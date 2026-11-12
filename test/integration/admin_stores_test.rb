# frozen_string_literal: true

require "test_helper"

class AdminStoresTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    sign_in users(:admin)
  end

  test "moderators can read stores but cannot suspend them" do
    sign_out users(:admin)
    sign_in users(:moderator)

    get admin_stores_path(locale: :en)
    assert_response :success

    get admin_store_path(stores(:confirmed_store), locale: :en)
    assert_response :success

    assert_no_changes -> { stores(:confirmed_store).reload.status } do
      post admin_store_suspension_path(stores(:confirmed_store), locale: :en),
           params: { reason: "Policy violation" }
    end
    assert_response :redirect
  end

  test "the index supports kind, status, verification and rating filters" do
    get admin_stores_path(locale: :en, kind: "business")
    assert_includes response.body, stores(:suspended_store).name
    assert_not_includes response.body, stores(:confirmed_store).name

    get admin_stores_path(locale: :en, verified: "true")
    assert_includes response.body, CGI.escapeHTML(stores(:confirmed_store).name)
    assert_not_includes response.body, stores(:suspended_store).name

    get admin_stores_path(locale: :en, status: "suspended")
    assert_includes response.body, stores(:suspended_store).name
    assert_not_includes response.body, stores(:confirmed_store).name
  end

  test "CSV export includes store contacts" do
    get admin_stores_path(locale: :en, kind: "individual", format: :csv)

    assert_response :success
    assert_includes response.body, stores(:confirmed_store).name
    assert_not_includes response.body, stores(:suspended_store).name
  end

  test "the show page renders legal, payout and review sections" do
    get admin_store_path(stores(:suspended_store), locale: :en)

    assert_response :success
    assert_includes response.body, stores(:suspended_store).name
    assert_includes response.body, I18n.t("admin.stores.show.legal_title", locale: :en)
    assert_includes response.body, I18n.t("admin.stores.show.payouts_title", locale: :en)
  end

  test "verifying and unverifying update verified_at" do
    store = stores(:suspended_store)

    post admin_store_verification_path(store, locale: :en)
    assert_redirected_to admin_store_path(store, locale: :en)
    assert store.reload.verified?

    delete admin_store_verification_path(store, locale: :en)
    assert_not store.reload.verified?
  end

  test "suspending a store hides its listings and emails the seller" do
    store = stores(:confirmed_store)
    listing = listings(:published_gpu)
    assert Listing.visible.exists?(listing.id)

    assert_emails 1 do
      assert_difference "AdminAuditLog.count", 1 do
        post admin_store_suspension_path(store, locale: :en), params: { reason: "Counterfeit goods" }
      end
    end

    assert_redirected_to admin_store_path(store, locale: :en)
    assert store.reload.suspended?
    assert_not Listing.visible.exists?(listing.id)
    assert_equal "store.suspended", AdminAuditLog.last.action
  end

  test "reactivating a store makes its listings visible again" do
    store = stores(:suspended_store)
    listing = listings(:suspended_listing)

    delete admin_store_suspension_path(store, locale: :en)

    assert_redirected_to admin_store_path(store, locale: :en)
    assert store.reload.active?
    assert Listing.visible.exists?(listing.id)
  end

  test "reviews can be hidden and shown" do
    store = stores(:confirmed_store)
    order = create_order!(store: store, status: "completed", delivered_at: Time.current)
    review = Review.create!(
      order: order, reviewer: order.buyer, store: store,
      rating: 4, body: "A perfectly reasonable review body."
    )

    post admin_store_review_visibility_path(store, review, locale: :en)
    assert review.reload.hidden?

    delete admin_store_review_visibility_path(store, review, locale: :en)
    assert review.reload.visible?
  end
end
