# frozen_string_literal: true

require "test_helper"

class SellListingsWizardTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:confirmed)
  end

  teardown do
    Setting.set(:listings_require_approval, true)
    Setting.set(:max_images_per_listing, 12)
  end

  test "a seller can complete the wizard and submit for review" do
    listing = create_draft
    add_photo(listing)
    save_details(listing)
    save_price(listing)

    patch sell_listing_path(listing, locale: :en), params: {
      listing: {}, step: "review", commit: "submit"
    }

    assert_redirected_to listing_path(listing, locale: :en)
    listing.reload
    assert_equal "pending_review", listing.status
    assert listing.submitted_at.present?
  end

  test "submitting publishes directly when approval is disabled" do
    Setting.set(:listings_require_approval, false)

    listing = create_draft
    add_photo(listing)
    save_details(listing)
    save_price(listing)

    patch sell_listing_path(listing, locale: :en), params: {
      listing: {}, step: "review", commit: "submit"
    }

    listing.reload
    assert_equal "published", listing.status
    assert listing.published_at.present?
  end

  test "the photo limit is enforced with a translated error" do
    Setting.set(:max_images_per_listing, 1)
    listing = create_draft

    patch sell_listing_path(listing, locale: :en), params: {
      listing: { images: [
        fixture_file_upload("listing.png", "image/png"),
        fixture_file_upload("listing.png", "image/png")
      ] },
      step: "photos"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("listings.errors.too_many_photos", max: 1, locale: :en)
    assert_equal 0, listing.reload.photos.count
  end

  test "the photos step reorders existing photos" do
    listing = create_draft
    add_photo(listing)
    first = listing.photos.first
    second = listing.photos.create!(
      image: fixture_file_upload("listing.png", "image/png")
    )

    patch sell_listing_path(listing, locale: :en), params: {
      listing: { photo_order: [ second.id, first.id ] },
      step: "photos"
    }

    assert_redirected_to edit_sell_listing_path(listing, step: "details", locale: :en)
    assert_equal [ second.id, first.id ], listing.reload.photos.map(&:id)
  end

  test "the compare-at price must be higher than the selling price" do
    listing = create_draft
    add_photo(listing)
    save_details(listing)

    patch sell_listing_path(listing, locale: :en), params: {
      listing: {
        price: "500.00",
        compare_at_price: "400.00",
        quantity: "1",
        shipping_mode: "shipping",
        shipping_price: "0",
        handling_days: "3",
        region_id: regions(:madrid).id,
        city: "Madrid",
        postal_code: "28001"
      },
      step: "price"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("listings.errors.compare_at_price", locale: :en)
    assert_nil listing.reload.price_cents
  end

  test "the wizard validates each step in its own context" do
    listing = create_draft

    patch sell_listing_path(listing, locale: :en), params: {
      listing: { title: "Only a title" }, step: "details"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("listings.errors.required_specs", attributes: "GPU chipset", locale: :en)
  end

  test "the review step renders the buyer preview and checklist" do
    listing = create_draft
    add_photo(listing)
    save_details(listing)
    save_price(listing)

    get edit_sell_listing_path(listing, step: "review", locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("sell.review.preview_title", locale: :en)
    assert_includes response.body, I18n.t("sell.review.checklist_ok", locale: :en)
  end

  test "editing a published listing shows the review warning" do
    get edit_sell_listing_path(listings(:published_gpu), step: "details", locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("sell.steps.published_warning", locale: :en)
  end

  test "owners delete drafts but archive non-draft listings" do
    assert_difference "Listing.count", -1 do
      delete sell_listing_path(listings(:draft_gpu), locale: :en)
    end

    assert_redirected_to sell_listings_path(tab: "drafts", locale: :en)

    published = listings(:published_gpu)
    assert_no_difference "Listing.count" do
      delete sell_listing_path(published, locale: :en)
    end

    assert published.reload.archived?
    assert_redirected_to sell_listings_path(tab: "archived", locale: :en)
  end

  private

  def create_draft
    assert_difference "Listing.count", 1 do
      post sell_listings_path(locale: :en), params: {
        listing: { category_id: categories(:gpus).id },
        step: "category"
      }
    end

    assert_redirected_to edit_sell_listing_path(Listing.order(:id).last, step: "photos", locale: :en)
    Listing.order(:id).last
  end

  def add_photo(listing)
    assert_difference -> { listing.photos.count }, 1 do
      patch sell_listing_path(listing, locale: :en), params: {
        listing: { images: [ fixture_file_upload("listing.png", "image/png") ] },
        step: "photos"
      }
    end

    assert_redirected_to edit_sell_listing_path(listing, step: "details", locale: :en)
  end

  def save_details(listing)
    patch sell_listing_path(listing, locale: :en), params: {
      listing: {
        title: "NVIDIA RTX 4070 Ti Super 16 GB",
        description: "A powerful graphics card in excellent condition, fully tested.",
        condition: "used_like_new",
        specs: { "gpu_chipset" => "nvidia" },
        seller_tag_ids: [ tags(:verified_seller).id ]
      },
      step: "details"
    }

    assert_redirected_to edit_sell_listing_path(listing, step: "price", locale: :en)
  end

  def save_price(listing)
    patch sell_listing_path(listing, locale: :en), params: {
      listing: {
        price: "799.00",
        compare_at_price: "899.00",
        quantity: "1",
        shipping_mode: "shipping",
        shipping_price: "0",
        free_shipping: "1",
        handling_days: "3",
        region_id: regions(:madrid).id,
        city: "Madrid",
        postal_code: "28001"
      },
      step: "price"
    }

    assert_redirected_to edit_sell_listing_path(listing, step: "review", locale: :en)
  end
end
