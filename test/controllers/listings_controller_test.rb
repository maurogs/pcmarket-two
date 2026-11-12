# frozen_string_literal: true

require "test_helper"

class ListingsControllerTest < ActionDispatch::IntegrationTest
  test "renders a published listing publicly" do
    get "/en/l/rtx-4070-ti-super"

    assert_response :success
    assert_includes response.body, "NVIDIA GeForce RTX 4070 Ti Super"
    assert_includes response.body, I18n.t("listings.show.buy_now", locale: :en)
    assert_includes response.body, "Buyer protection"
    assert_includes response.body, '"@type":"Product"'
    assert_includes response.body, '"@type":"BreadcrumbList"'
  end

  test "returns 404 for a pending listing to visitors" do
    get "/en/l/pending-review-gpu"

    assert_response :not_found
  end

  test "shows the status banner to the owner" do
    sign_in users(:confirmed)

    get "/en/l/pending-review-gpu"

    assert_response :success
    assert_includes response.body,
                    I18n.t("listings.show.status_banner",
                           status: I18n.t("listings.statuses.pending_review", locale: :en),
                           locale: :en)
    assert_includes response.body, I18n.t("listings.show.status_visibility", locale: :en)
  end

  test "shows the status banner to admins" do
    sign_in users(:admin)

    get "/en/l/pending-review-gpu"

    assert_response :success
    assert_includes response.body,
                    I18n.t("listings.show.status_banner",
                           status: I18n.t("listings.statuses.pending_review", locale: :en),
                           locale: :en)
  end

  test "shows a rejection reason to the owner" do
    listings(:pending_gpu).update_columns(status: "rejected", rejection_reason: "Missing photos")
    sign_in users(:confirmed)

    get "/en/l/pending-review-gpu"

    assert_response :success
    assert_includes response.body, I18n.t("listings.show.rejection_reason", reason: "Missing photos", locale: :en)
  end

  test "redirects an old listing slug permanently" do
    listing = listings(:published_gpu)
    FriendlyId::Slug.create!(sluggable: listing, slug: "old-rtx-listing")
    listing.update!(slug: "new-rtx-listing")

    get "/en/l/old-rtx-listing"

    assert_response :moved_permanently
    assert_redirected_to "/en/l/new-rtx-listing"
  end

  test "increments views at most once per session" do
    listing = listings(:published_gpu)
    initial = listing.views_count

    get "/en/l/rtx-4070-ti-super"
    assert_equal initial + 1, listing.reload.views_count

    get "/en/l/rtx-4070-ti-super"
    assert_equal initial + 1, listing.reload.views_count
  end

  test "renders a photo gallery and product image" do
    Setting.set(:listings_require_approval, false)
    listing = listings(:published_gpu)
    photo = ListingPhoto.new(listing: listing, position: 0)
    photo.image.attach(
      io: File.open(file_fixture("listing.png")),
      filename: "listing.png",
      content_type: "image/png"
    )
    photo.save!

    get "/en/l/rtx-4070-ti-super"

    assert_response :success
    assert_includes response.body, 'data-controller="gallery"'
    assert_includes response.body, 'data-gallery-target="main"'
    assert_includes response.body, 'property="og:image"'
  end

  test "sets an ETag for anonymous listing pages" do
    get "/en/l/rtx-4070-ti-super"

    assert_response :success
    assert response.headers["ETag"].present?
  end
end
