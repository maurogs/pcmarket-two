# frozen_string_literal: true

require "test_helper"

class SellListingsIndexTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:confirmed)
  end

  teardown do
    Setting.set(:listings_require_approval, true)
  end

  test "each tab shows only the listings for its statuses" do
    get sell_listings_path(locale: :en)

    assert_response :success
    assert_includes response.body, 'id="bulk-archive-form"'
    assert_includes response.body, listings(:published_gpu).title
    assert_includes response.body, listings(:reserved_gpu).title
    assert_not_includes response.body, listings(:draft_gpu).title
    assert_not_includes response.body, listings(:pending_gpu).title
    assert_not_includes response.body, listings(:rejected_gpu).title
    assert_not_includes response.body, listings(:sold_gpu).title
    assert_not_includes response.body, listings(:archived_gpu).title
    assert_not_includes response.body, listings(:suspended_listing).title

    get sell_listings_path(tab: "pending_review", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_not_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:draft_gpu).title

    get sell_listings_path(tab: "drafts", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:draft_gpu).title
    assert_not_includes response.body, listings(:published_gpu).title

    get sell_listings_path(tab: "rejected", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:rejected_gpu).title
    assert_includes response.body, listings(:rejected_gpu).rejection_reason
    assert_includes response.body, I18n.t("sell.listings.rejected.resubmit", locale: :en)
    assert_not_includes response.body, listings(:pending_gpu).title

    get sell_listings_path(tab: "sold", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:sold_gpu).title
    assert_not_includes response.body, listings(:published_gpu).title

    get sell_listings_path(tab: "archived", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:archived_gpu).title
    assert_not_includes response.body, listings(:sold_gpu).title
  end

  test "an invalid tab falls back to active" do
    get sell_listings_path(tab: "not-a-tab", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:draft_gpu).title
  end

  test "the title filter narrows the listings" do
    get sell_listings_path(q: "Ryzen", locale: :en)

    assert_response :success
    assert_includes response.body, listings(:cpu_listing).title
    assert_not_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:reserved_gpu).title
  end

  test "bulk archive archives only the seller's own archivable listings" do
    own = listings(:published_gpu)
    sold = listings(:sold_gpu)
    other_seller = listings(:suspended_listing)

    post bulk_archive_path(locale: :en), params: {
      bulk_archive: { listing_ids: [ own.id, sold.id, other_seller.id ] },
      tab: "active"
    }

    assert_redirected_to sell_listings_path(tab: "active", locale: :en)
    assert_equal I18n.t("sell.listings.bulk.archived", count: 1, locale: :en), flash[:notice]
    assert own.reload.archived?
    assert sold.reload.sold?
    assert other_seller.reload.published?
  end

  test "bulk archive with blank ids shows a translated alert" do
    post bulk_archive_path(locale: :en), params: {
      bulk_archive: { listing_ids: [ "" ] },
      tab: "active"
    }

    assert_redirected_to sell_listings_path(tab: "active", locale: :en)
    assert_equal I18n.t("sell.listings.bulk.nothing_selected", locale: :en), flash[:alert]
  end

  test "republish sends an archived listing back to review" do
    archived = listings(:archived_gpu)

    post sell_listing_republish_path(archived, locale: :en)

    assert_redirected_to sell_listings_path(locale: :en)
    assert_equal I18n.t("sell.flash.submitted", locale: :en), flash[:notice]
    archived.reload
    assert archived.pending_review?
    assert_nil archived.archived_at
  end

  test "republish alerts when the listing cannot be republished" do
    post sell_listing_republish_path(listings(:published_gpu), locale: :en)

    assert_redirected_to sell_listings_path(locale: :en)
    assert_equal I18n.t("sell.listings.flash.cannot_republish", locale: :en), flash[:alert]
  end

  test "the index is paginated" do
    insert_bulk_listings(categories(:gpus), count: 22, prefix: "Paged")

    get sell_listings_path(locale: :en)

    assert_response :success
    assert_includes response.body, "page=2"

    get sell_listings_path(page: 2, locale: :en)

    assert_response :success
  end
end
