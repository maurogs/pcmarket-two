# frozen_string_literal: true

require "test_helper"

class AdminListingsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    sign_in users(:admin)
  end

  test "regular users cannot reach the listings index" do
    sign_out users(:admin)
    sign_in users(:confirmed)

    get admin_listings_path(locale: :en)

    assert_response :not_found
  end

  test "the index lists listings and supports search and status filters" do
    get admin_listings_path(locale: :en)

    assert_response :success
    assert_includes response.body, listings(:published_gpu).title

    get admin_listings_path(locale: :en, q: "Draft GPU")

    assert_response :success
    assert_includes response.body, listings(:draft_gpu).title
    assert_not_includes response.body, listings(:published_gpu).title

    get admin_listings_path(locale: :en, status: "draft")

    assert_response :success
    assert_includes response.body, listings(:draft_gpu).title
    assert_not_includes response.body, listings(:published_gpu).title
  end

  test "the index filters by category subtree, seller, store kind and price" do
    get admin_listings_path(locale: :en, category: categories(:gpus).slug)
    assert_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:cpu_listing).title

    get admin_listings_path(locale: :en, seller_id: users(:seller_two).id)
    assert_includes response.body, listings(:suspended_listing).title
    assert_not_includes response.body, listings(:published_gpu).title

    get admin_listings_path(locale: :en, price_min: "700", price_max: "900")
    assert_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:nvidia_budget).title
  end

  test "sorting by price ascending puts the cheapest listing first" do
    get admin_listings_path(locale: :en, sort: "price", direction: "asc")

    assert_response :success
    assert response.body.index(listings(:nvidia_budget).title) <
           response.body.index(listings(:published_gpu).title)
  end

  test "CSV export streams the filtered set with translated headers" do
    get admin_listings_path(locale: :en, status: "published", format: :csv)

    assert_response :success
    assert_match %r{text/csv}, response.media_type
    assert_includes response.body, I18n.t("admin.listings.csv.title", locale: :en)
    assert_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:draft_gpu).title
  end

  test "a listing show page renders its moderation and report panels" do
    get admin_listing_path(listings(:pending_gpu), locale: :en)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_includes response.body, I18n.t("admin.listings.show.history_title", locale: :en)
    assert_includes response.body, I18n.t("admin.listings.show.actions_title", locale: :en)
  end

  test "approving a pending listing publishes it and writes an audit entry" do
    listing = listings(:pending_gpu)

    assert_difference "AdminAuditLog.count", 1 do
      post admin_listing_approval_path(listing, locale: :en)
    end

    assert_redirected_to admin_listing_path(listing, locale: :en)
    assert_equal "published", listing.reload.status
    assert_equal "listing.approved", AdminAuditLog.last.action
  end

  test "rejecting requires a reason and notifies the seller" do
    listing = listings(:pending_gpu)

    post admin_listing_rejection_path(listing, locale: :en)

    assert_redirected_to admin_listing_path(listing, locale: :en)
    assert_equal "pending_review", listing.reload.status

    assert_enqueued_emails 1 do
      post admin_listing_rejection_path(listing, locale: :en),
           params: { reason_code: "misleading_description", reason_text: "Fix the title" }
    end
    assert_equal "rejected", listing.reload.status
  end

  test "featuring sets featured_until regardless of the paid flag" do
    listing = listings(:amd_gpu)
    listing.update_columns(featured_until: nil)

    post admin_listing_feature_path(listing, locale: :en),
         params: { days: "5" }

    assert_redirected_to admin_listing_path(listing, locale: :en)
    assert listing.reload.featured_until > 4.days.from_now
  end

  test "product labels are admin-only and keep seller tags" do
    listing = listings(:published_gpu)
    listing.tag_ids = [ tags(:verified_seller).id ]
    label = tags(:featured)

    post admin_listing_label_path(listing, locale: :en),
         params: { product_label_ids: [ label.id ] }

    assert_redirected_to admin_listing_path(listing, locale: :en)
    assert_includes listing.reload.tag_ids, label.id
    assert_includes listing.reload.tag_ids, tags(:verified_seller).id
  end

  test "a draft without orders can be deleted permanently" do
    listing = listings(:draft_gpu)

    assert_difference "Listing.count", -1 do
      delete admin_listing_path(listing, locale: :en)
    end

    assert_redirected_to admin_listings_path(locale: :en)
    assert_equal "listing.destroyed", AdminAuditLog.last.action
  end

  test "a published listing cannot be deleted permanently" do
    listing = listings(:published_gpu)

    assert_no_difference "Listing.count" do
      delete admin_listing_path(listing, locale: :en)
    end

    assert_redirected_to admin_listing_path(listing, locale: :en)
  end

  test "bulk approve publishes every selected listing and audits the batch" do
    assert_difference "AdminAuditLog.count", 1 do
      post admin_listing_bulk_actions_path(locale: :en),
           params: { operation: "approve",
                     listing_ids: [ listings(:pending_gpu).id, listings(:pending_nvidia_gpu).id ] }
    end

    assert_redirected_to admin_listings_path(locale: :en)
    assert_equal "published", listings(:pending_gpu).reload.status
    assert_equal "published", listings(:pending_nvidia_gpu).reload.status
  end

  test "moderators cannot feature or label listings in bulk" do
    sign_out users(:admin)
    sign_in users(:moderator)

    post admin_listing_bulk_actions_path(locale: :en),
         params: { operation: "feature", days: "3", listing_ids: [ listings(:published_gpu).id ] }

    assert_redirected_to admin_listings_path(locale: :en)
    assert_equal I18n.t("admin.listings.bulk.admins_only", locale: :en), flash[:alert]
  end

  test "the edit form reuses the dynamic attribute inputs" do
    get edit_admin_listing_path(listings(:published_gpu), locale: :en)

    assert_response :success
    assert_includes response.body, "listing[specs][gpu_chipset]"
    assert_includes response.body, I18n.t("admin.listings.edit.title", locale: :en)
  end
end
