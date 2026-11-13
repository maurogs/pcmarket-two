# frozen_string_literal: true

require "test_helper"

class ApiV1BuyerTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:moderator)
    @token = issue_api_session(@buyer).at(1)
    @headers = api_headers(@token)
    @listing = listings(:published_gpu)
    @store = stores(:confirmed_store)
  end

  test "favourites can be listed, created and destroyed" do
    post api_v1_favourites_path, params: { listing_id: @listing.id }, headers: @headers, as: :json
    assert_response :created
    favourite_id = json_data["id"]
    assert_equal @listing.id, json_data.dig("listing", "id")

    get api_v1_favourites_path, headers: @headers, as: :json
    assert_response :success
    assert_equal [ favourite_id ], json_data.map { |favourite| favourite["id"] }

    delete api_v1_favourite_path(favourite_id), headers: @headers, as: :json
    assert_response :no_content
    assert_not Favourite.exists?(favourite_id)
  end

  test "a buyer cannot destroy another buyer's favourite" do
    favourite = Favourite.create!(user: users(:seller_two), listing: @listing)

    delete api_v1_favourite_path(favourite), headers: @headers, as: :json
    assert_response :not_found
  end

  test "follows can be listed, created and destroyed" do
    post api_v1_follows_path, params: { store_id: @store.slug }, headers: @headers, as: :json
    assert_response :created
    follow_id = json_data["id"]

    get api_v1_follows_path, headers: @headers, as: :json
    assert_response :success
    assert_equal [ follow_id ], json_data.map { |follow| follow["id"] }

    delete api_v1_follow_path(follow_id), headers: @headers, as: :json
    assert_response :no_content
  end

  test "saved searches support CRUD" do
    post api_v1_saved_searches_path, headers: @headers, params: {
      saved_search: {
        name: "RTX deals", category_id: categories(:gpus).id,
        frequency: "instant", email_alerts: true,
        query_params: { q: "RTX", condition: [ "used_like_new" ] }
      }
    }, as: :json

    assert_response :created
    id = json_data["id"]
    assert_equal "RTX", json_data.dig("query_params", "q")

    patch api_v1_saved_search_path(id), headers: @headers,
          params: { saved_search: { name: "RTX bargains" } }, as: :json
    assert_response :success
    assert_equal "RTX bargains", json_data["name"]

    get api_v1_saved_searches_path, headers: @headers, as: :json
    assert_response :success
    assert_equal 1, json_data.size

    delete api_v1_saved_search_path(id), headers: @headers, as: :json
    assert_response :no_content
  end

  test "a buyer cannot update another buyer's saved search" do
    saved = SavedSearch.create!(user: users(:seller_two), name: "Other search")

    patch api_v1_saved_search_path(saved), headers: @headers,
          params: { saved_search: { name: "Hijack" } }, as: :json
    assert_response :not_found
  end

  test "manages the cart and its items" do
    post api_v1_cart_items_path, headers: @headers,
         params: { listing_id: @listing.id, quantity: 1 }, as: :json
    assert_response :created
    item_id = json_data["id"]

    get api_v1_cart_path, headers: @headers, as: :json
    assert_response :success
    assert_equal 1, json_data["item_count"]
    assert_equal 1, json_data["items"].size

    patch api_v1_cart_item_path(item_id), headers: @headers,
          params: { quantity: 1 }, as: :json
    assert_response :success
    assert_equal 1, json_data["quantity"]

    delete api_v1_cart_item_path(item_id), headers: @headers, as: :json
    assert_response :no_content
    assert_equal 0, @buyer.cart.reload.items.count
  end

  test "a buyer cannot add their own listing to the cart" do
    seller = users(:confirmed)
    token = issue_api_session(seller).at(1)

    post api_v1_cart_items_path, headers: api_headers(token),
         params: { listing_id: @listing.id }, as: :json

    assert_response :unprocessable_content
    assert_equal "validation_failed", json.dig("error", "code")
  end

  test "checkout returns the PaymentSheet client secret and customer details" do
    post api_v1_cart_items_path, headers: @headers,
         params: { listing_id: @listing.id }, as: :json
    assert_response :created

    post api_v1_checkouts_path, headers: @headers, params: {
      email: @buyer.email,
      terms_accepted: "1",
      idempotency_key: "api-checkout-1",
      address: default_address_attributes,
      fulfilment: { @store.id.to_s => "shipping" }
    }, as: :json

    assert_response :created
    payment = json_data.fetch("payment")
    assert payment["client_secret"].present?
    assert payment["publishable_key"].present?
    assert payment["ephemeral_key_secret"].present?
    assert payment["customer_id"].present?
    assert_equal payment["payment_intent_id"],
                 json_data.dig("checkout", "payment_intent_id")
    assert_equal payment["customer_id"], @buyer.reload.stripe_customer_id

    checkout_id = json_data.dig("checkout", "id")
    get api_v1_checkout_path(checkout_id), headers: @headers, as: :json
    assert_response :success
    assert_equal "pending", json_data["status"]
  end

  test "a buyer cannot read another buyer's checkout" do
    other = Checkout.create!(
      buyer: users(:seller_two), email: "other@example.com",
      shipping_address: default_address_attributes.stringify_keys
    )

    get api_v1_checkout_path(other), headers: @headers, as: :json
    assert_response :not_found
  end

  test "addresses support CRUD" do
    post api_v1_addresses_path, headers: @headers,
         params: { address: default_address_attributes }, as: :json
    assert_response :created
    id = json_data["id"]
    assert_equal "Madrid", json_data["city"]

    get api_v1_addresses_path, headers: @headers, as: :json
    assert_response :success
    assert_equal [ id ], json_data.map { |address| address["id"] }

    patch api_v1_address_path(id), headers: @headers,
          params: { address: { city: "Alcalá de Henares" } }, as: :json
    assert_response :success
    assert_equal "Alcalá de Henares", json_data["city"]

    delete api_v1_address_path(id), headers: @headers, as: :json
    assert_response :no_content
  end

  test "a buyer cannot update another buyer's address" do
    address = Address.create!(default_address_attributes.merge(user: users(:seller_two)))

    patch api_v1_address_path(address), headers: @headers,
          params: { address: { city: "Hijack" } }, as: :json
    assert_response :not_found
  end

  test "orders can be listed, shown, cancelled and reported" do
    paid_order = create_order!(buyer: @buyer, store: @store, status: "paid")
    create_order!(buyer: @buyer, store: @store, status: "shipped")

    get api_v1_orders_path, headers: @headers, as: :json
    assert_response :success
    assert json_data.size >= 2

    get api_v1_order_path(paid_order), headers: @headers, as: :json
    assert_response :success
    assert_equal paid_order.number, json_data["number"]

    post api_v1_order_problem_report_path(paid_order), headers: @headers,
         params: { reason: "damaged", details: "The box arrived open." }, as: :json
    assert_response :accepted
    assert_equal "problem_reported", paid_order.events.last.event

    post api_v1_order_cancellation_path(paid_order), headers: @headers,
         params: { reason: "changed my mind" }, as: :json
    assert_response :success
    assert_equal "cancelled", json_data["status"]
  end

  test "a buyer confirms delivery on a shipped order" do
    order = create_order!(buyer: @buyer, store: @store, status: "shipped",
                          shipped_at: 1.day.ago)

    post api_v1_order_delivery_confirmation_path(order), headers: @headers, as: :json

    assert_response :success
    assert_equal "delivered", json_data["status"]
    assert order.reload.delivered_at.present?
  end

  test "a buyer cannot read another buyer's order" do
    other = create_order!(buyer: users(:seller_two), store: @store, status: "paid")

    get api_v1_order_path(other), headers: @headers, as: :json
    assert_response :not_found
  end

  test "reviews can be created and updated" do
    order = create_order!(buyer: @buyer, store: @store, status: "delivered",
                          delivered_at: 1.day.ago)

    post api_v1_order_review_path(order), headers: @headers,
         params: { review: { rating: 5, body: "Excellent seller, fast delivery." } },
         as: :json
    assert_response :created
    assert_equal 5, json_data["rating"]

    patch api_v1_order_review_path(order), headers: @headers,
          params: { review: { body: "Still excellent after using it for a day." } },
          as: :json
    assert_response :success
    assert_equal "Still excellent after using it for a day.", json_data["body"]
  end

  test "a buyer cannot review another buyer's order" do
    other = create_order!(buyer: users(:seller_two), store: @store, status: "delivered",
                          delivered_at: 1.day.ago)

    post api_v1_order_review_path(other), headers: @headers,
         params: { review: { rating: 5, body: "Not my order at all." } }, as: :json
    assert_response :not_found
  end
end
