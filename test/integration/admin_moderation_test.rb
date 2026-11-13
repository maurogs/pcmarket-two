# frozen_string_literal: true

require "test_helper"

class AdminModerationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    sign_in users(:moderator)
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
  end

  test "the queue shows only pending listings" do
    get admin_listing_reviews_path(locale: :en)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_not_includes response.body, listings(:published_gpu).title
    assert_not_includes response.body, listings(:draft_gpu).title
    assert_not_includes response.body, listings(:rejected_gpu).title
  end

  test "the category filter includes child categories" do
    get admin_listing_reviews_path(locale: :en, category: categories(:gpus).slug)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_includes response.body, listings(:pending_nvidia_gpu).title
    assert_not_includes response.body, listings(:pending_business_gpu).title
  end

  test "the seller kind filter splits individuals and businesses" do
    get admin_listing_reviews_path(locale: :en, seller_kind: "business")

    assert_response :success
    assert_includes response.body, listings(:pending_business_gpu).title
    assert_not_includes response.body, listings(:pending_gpu).title

    get admin_listing_reviews_path(locale: :en, seller_kind: "individual")

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_not_includes response.body, listings(:pending_business_gpu).title
  end

  test "the has-photos filter uses the listing photos" do
    with_photo = listings(:pending_business_gpu)
    attach_photo(with_photo)

    get admin_listing_reviews_path(locale: :en, photos: "with")

    assert_response :success
    assert_includes response.body, with_photo.title
    assert_not_includes response.body, listings(:pending_gpu).title

    get admin_listing_reviews_path(locale: :en, photos: "without")

    assert_response :success
    assert_not_includes response.body, with_photo.title
    assert_includes response.body, listings(:pending_gpu).title
  end

  test "the review page shows the buyer preview, seller details and reason choices" do
    get admin_listing_review_path(listings(:pending_gpu), locale: :en)

    assert_response :success
    assert_includes response.body, listings(:pending_gpu).title
    assert_includes response.body, listings(:pending_gpu).description
    assert_includes response.body, listings(:pending_gpu).seller.display_name
    assert_includes response.body, ERB::Util.html_escape(listings(:pending_gpu).store.name)
    assert_includes response.body, I18n.t("admin.moderation.show.buyer_preview", locale: :en)

    ListingModeration::REJECTION_REASONS.each do |code|
      assert_includes response.body, I18n.t("admin.moderation.reasons.#{code}", locale: :en)
    end

    assert_includes response.body, I18n.t("admin.moderation.history.empty", locale: :en)
    assert_includes response.body, admin_listing_review_path(listings(:pending_business_gpu), locale: :en)
  end

  test "the review page lists previous moderation decisions" do
    listing = listings(:pending_gpu)
    moderation = ListingModeration.create!(listing: listing, moderator: users(:admin),
                                           action: :rejected, reason: "Old photos")

    get admin_listing_review_path(listing, locale: :en)

    assert_response :success
    assert_includes response.body, moderation.moderator.display_name
    assert_includes response.body, I18n.t("admin.moderation.actions.rejected", locale: :en)
    assert_includes response.body, moderation.reason
  end

  test "approving publishes the listing, writes the log, bumps counters and emails the seller" do
    listing = listings(:pending_gpu)
    store = listing.store
    category = listing.category
    store_before = store.listings_count
    category_before = category.listings_count

    perform_enqueued_jobs do
      patch admin_listing_review_path(listing, locale: :en), params: { decision: "approve" }
    end

    assert_redirected_to admin_listing_review_path(listings(:pending_business_gpu), locale: :en)
    assert_equal I18n.t("admin.moderation.notices.approved", locale: :en), flash[:notice]

    listing.reload
    assert listing.published?
    assert listing.published_at.present?

    moderation = ListingModeration.find_by!(listing: listing)
    assert_equal "approved", moderation.action

    assert_equal store_before + 1, store.reload.listings_count
    assert_equal category_before + 1, category.reload.listings_count

    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    assert_equal [ listing.seller.email ], email.to
    assert_equal I18n.t("listing_mailer.approved.subject", locale: :es), email.subject
  end

  test "rejecting without a reason keeps the listing pending and warns" do
    listing = listings(:pending_gpu)

    assert_no_difference -> { ListingModeration.count } do
      patch admin_listing_review_path(listing, locale: :en), params: { decision: "reject" }
    end

    assert_redirected_to admin_listing_review_path(listing, locale: :en)
    assert_equal I18n.t("admin.moderation.notices.reason_required", locale: :en), flash[:alert]
    assert listing.reload.pending_review?
    assert_no_enqueued_emails
  end

  test "rejecting with a reason stores the translated label, the note and emails the seller" do
    listing = listings(:pending_gpu)
    label = I18n.t("admin.moderation.reasons.poor_photos", locale: :es)
    note = "Faltan fotos del lateral."

    perform_enqueued_jobs do
      patch admin_listing_review_path(listing, locale: :en),
            params: { decision: "reject", reason_code: "poor_photos", reason_text: note }
    end

    assert_redirected_to admin_listing_review_path(listings(:pending_business_gpu), locale: :en)
    assert_equal I18n.t("admin.moderation.notices.rejected", locale: :en), flash[:notice]

    listing.reload
    assert listing.rejected?
    assert_includes listing.rejection_reason, label
    assert_includes listing.rejection_reason, note

    moderation = ListingModeration.find_by!(listing: listing)
    assert_equal "rejected", moderation.action
    assert_equal listing.rejection_reason, moderation.reason

    assert_equal 1, ActionMailer::Base.deliveries.size
    email = ActionMailer::Base.deliveries.last
    assert_equal I18n.t("listing_mailer.rejected.subject", locale: :es), email.subject
    assert_includes email.text_part.body.to_s, listing.rejection_reason
  end

  test "an invalid decision is rejected with a translated alert" do
    listing = listings(:pending_gpu)

    patch admin_listing_review_path(listing, locale: :en), params: { decision: "maybe" }

    assert_redirected_to admin_listing_review_path(listing, locale: :en)
    assert_equal I18n.t("admin.moderation.notices.invalid_decision", locale: :en), flash[:alert]
    assert listing.reload.pending_review?
  end

  test "a second decision on the same listing shows the already moderated alert" do
    listing = listings(:pending_gpu)

    patch admin_listing_review_path(listing, locale: :en), params: { decision: "approve" }
    assert listing.reload.published?

    assert_no_difference -> { ListingModeration.count } do
      patch admin_listing_review_path(listing, locale: :en), params: { decision: "approve" }
    end

    assert_redirected_to admin_listing_review_path(listings(:pending_business_gpu), locale: :en)
    assert_equal I18n.t("admin.moderation.notices.already_moderated", locale: :en), flash[:alert]
    assert_enqueued_emails 1
  end

  private

  def attach_photo(listing)
    photo = listing.photos.create!(position: 0)
    photo.image.attach(
      io: File.open(file_fixture("listing.png")),
      filename: "listing.png",
      content_type: "image/png"
    )
  end
end
