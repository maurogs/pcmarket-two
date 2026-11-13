# frozen_string_literal: true

require "test_helper"

class ApiV1SellerTest < ActionDispatch::IntegrationTest
  setup do
    @seller = users(:confirmed)
    @token = issue_api_session(@seller).at(1)
    @headers = api_headers(@token)
    @store = stores(:confirmed_store)
    Setting.set(:listings_require_approval, true)
  end

  teardown do
    Setting.set(:listings_require_approval, true)
    Setting.set(:max_images_per_listing, 12)
  end

  test "shows and updates my store" do
    get api_v1_my_store_path, headers: @headers, as: :json
    assert_response :success
    assert_equal @store.id, json_data["id"]

    patch api_v1_my_store_path, headers: @headers,
          params: { store: { description: "Updated store description." } }, as: :json
    assert_response :success
    assert_equal "Updated store description.", @store.reload.description
  end

  test "creates a store for a seller without one" do
    user = users(:moderator)
    token = issue_api_session(user).at(1)

    post api_v1_my_store_path, headers: api_headers(token), params: {
      store: {
        kind: "individual", name: "Fresh Store", region_id: regions(:madrid).id,
        city: "Madrid", country_code: "ES"
      }
    }, as: :json

    assert_response :created
    assert_equal "Fresh Store", user.reload.store.name
  end

  test "direct upload and photo attach with reorder" do
    first_signed_id = direct_upload("first.png")
    second_signed_id = direct_upload("second.png")

    post api_v1_sell_listings_path, headers: @headers,
         params: { listing: { category_id: categories(:gpus).id }, step: "category" },
         as: :json
    assert_response :created
    listing_id = json_data["id"]

    patch api_v1_sell_listing_path(listing_id), headers: @headers, params: {
      listing: { photo_signed_ids: [ first_signed_id, second_signed_id ] },
      step: "photos"
    }, as: :json

    assert_response :success
    listing = Listing.find(listing_id)
    assert_equal 2, listing.photos.count
    first_photo, second_photo = listing.photos.to_a

    patch api_v1_sell_listing_path(listing_id), headers: @headers, params: {
      listing: { photo_order: [ second_photo.id, first_photo.id ] },
      step: "photos"
    }, as: :json

    assert_response :success
    assert_equal [ second_photo.id, first_photo.id ], listing.reload.photos.map(&:id)
  end

  test "the wizard steps can be saved and the listing submitted, archived and republished" do
    listing = create_api_draft
    fill_api_listing(listing)

    post api_v1_sell_listing_submission_path(listing), headers: @headers, as: :json
    assert_response :success
    assert_equal "pending_review", listing.reload.status

    post api_v1_sell_listing_archival_path(listing), headers: @headers, as: :json
    assert_response :success
    assert_equal "archived", listing.reload.status

    post api_v1_sell_listing_republication_path(listing), headers: @headers, as: :json
    assert_response :success
    assert_equal "pending_review", listing.reload.status
  end

  test "a draft can be deleted but a published listing must be archived" do
    draft = create_api_draft

    delete api_v1_sell_listing_path(draft), headers: @headers, as: :json
    assert_response :no_content
    assert_not Listing.exists?(draft.id)

    published = listings(:published_gpu)
    delete api_v1_sell_listing_path(published), headers: @headers, as: :json
    assert_response :conflict
    assert_equal "conflict", json.dig("error", "code")
  end

  test "a seller cannot update or delete another seller's listing" do
    other_listing = listings(:published_gpu)
    other_token = issue_api_session(users(:seller_two)).at(1)

    patch api_v1_sell_listing_path(other_listing), headers: api_headers(other_token),
          params: { listing: { title: "Hijacked listing" }, step: "details" }, as: :json
    assert_response :forbidden

    delete api_v1_sell_listing_path(other_listing), headers: api_headers(other_token), as: :json
    assert_response :forbidden
  end

  test "seller listings index supports tabs" do
    get api_v1_sell_listings_path, headers: @headers, params: { tab: "active" }, as: :json

    assert_response :success
    assert json_meta["counts"].key?("active")
    assert json_data.all? { |listing| %w[published reserved].include?(listing["status"]) }
  end

  test "sales can be listed, shown, shipped and cancelled" do
    order = create_order!(buyer: users(:moderator), store: @store, status: "paid")

    get api_v1_sell_orders_path, headers: @headers, as: :json
    assert_response :success
    assert_equal [ order.id ], json_data.map { |entry| entry["id"] }

    get api_v1_sell_order_path(order), headers: @headers, as: :json
    assert_response :success

    post api_v1_sell_order_shipment_path(order), headers: @headers,
         params: { carrier: "correos", tracking_number: "TRACK123" }, as: :json
    assert_response :success
    assert_equal "shipped", order.reload.status
    assert_equal "TRACK123", order.tracking_number
  end

  test "a seller cannot ship another seller's order" do
    order = create_order!(buyer: users(:moderator), store: @store, status: "paid")
    other_token = issue_api_session(users(:seller_two)).at(1)

    post api_v1_sell_order_shipment_path(order), headers: api_headers(other_token),
         params: { carrier: "correos", tracking_number: "NOPE" }, as: :json
    assert_response :not_found
  end

  test "returns the analytics summary" do
    get api_v1_sell_analytics_path, headers: @headers, params: { range: 7 }, as: :json

    assert_response :success
    assert_equal 7, json_data["range"]
    assert json_data.key?("revenue_cents")
    assert json_data.key?("pending")
  end

  test "updates vacation mode" do
    get api_v1_vacation_path, headers: @headers, as: :json
    assert_response :success

    patch api_v1_vacation_path, headers: @headers, params: {
      store: {
        vacation_mode: true,
        vacation_message: "Back next week",
        vacation_until: 3.days.from_now.to_date
      }
    }, as: :json

    assert_response :success
    assert json_data["vacation_mode"]
    assert @store.reload.vacation_mode?
  end

  test "creates a Stripe Connect onboarding link" do
    fake = Object.new
    fake.define_singleton_method(:call) { "https://connect.stripe.example/onboard" }

    with_stub(Payments::ConnectOnboarding, :new, ->(**) { fake }) do
      post api_v1_stripe_connect_path, headers: @headers, as: :json
    end

    assert_response :success
    assert_equal "https://connect.stripe.example/onboard", json_data["url"]
  end

  private

  def direct_upload(filename)
    data = "image-bytes"
    post api_v1_direct_uploads_path, headers: @headers, params: {
      blob: {
        filename: filename,
        byte_size: data.bytesize,
        checksum: Digest::MD5.base64digest(data),
        content_type: "image/png",
        metadata: {}
      }
    }, as: :json

    assert_response :created
    blob = ActiveStorage::Blob.find_signed!(json_data["signed_id"])
    blob.upload(StringIO.new(data))
    json_data["signed_id"]
  end

  def create_api_draft
    post api_v1_sell_listings_path, headers: @headers,
         params: { listing: { category_id: categories(:gpus).id }, step: "category" },
         as: :json
    assert_response :created
    Listing.find(json_data["id"])
  end

  def fill_api_listing(listing)
    patch api_v1_sell_listing_path(listing), headers: @headers, params: {
      listing: {
        title: "API RTX 4080 graphics card",
        description: "A fully working graphics card in excellent condition.",
        condition: "used_like_new",
        specs: { gpu_chipset: "nvidia" }
      },
      step: "details"
    }, as: :json
    assert_response :success

    patch api_v1_sell_listing_path(listing), headers: @headers, params: {
      listing: {
        price: "550",
        quantity: 1,
        region_id: regions(:madrid).id,
        city: "Madrid",
        postal_code: "28001",
        shipping_mode: "shipping",
        shipping_price: "5",
        handling_days: 2
      },
      step: "price"
    }, as: :json
    assert_response :success

    # The review context still requires at least one photo.
    listing.photos.create!(image: fixture_file_upload("listing.png", "image/png"))
  end
end
