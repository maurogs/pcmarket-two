# frozen_string_literal: true

require "test_helper"

class SavedSearches::DigestJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @user = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    clear_enqueued_jobs
    clear_enqueued_jobs
    ActionMailer::Base.deliveries.clear
  end

  def search_for(name:, **attrs)
    SavedSearch.create!({
      user: @user,
      name: name,
      category: categories(:cpus),
      frequency: "daily",
      email_alerts: true,
      query_params: {}
    }.merge(attrs))
  end

  def listing(**attrs)
    create_listing!(**{
      store: @store,
      seller: @seller,
      category: categories(:cpus),
      title: "Fresh CPU listing",
      published_at: 1.minute.from_now
    }.merge(attrs))
  end

  test "groups two searches of the same user into a single digest email" do
    search_for(name: "Daily CPUs")
    search_for(name: "Weekly CPUs", frequency: "weekly")
    listing

    assert_enqueued_emails 1 do
      SavedSearches::DigestJob.perform_now
    end

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob
    email = ActionMailer::Base.deliveries.last

    assert_equal [ @user.email ], email.to
    assert_includes email.text_part.body.to_s, "Daily CPUs"
    assert_includes email.text_part.body.to_s, "Weekly CPUs"
  end

  test "a weekly search that was notified recently is not due" do
    search = search_for(name: "Weekly CPUs", frequency: "weekly",
                        last_notified_at: 2.days.ago)
    notified_at = search.last_notified_at
    listing

    assert_no_enqueued_emails do
      SavedSearches::DigestJob.perform_now
    end

    assert_equal notified_at, search.reload.last_notified_at
  end

  test "a daily search is due and updates its timestamps" do
    search = search_for(name: "Daily CPUs", last_notified_at: 2.days.ago)
    fresh = listing

    assert_enqueued_emails 1 do
      SavedSearches::DigestJob.perform_now
    end

    search.reload
    assert search.last_notified_at > 2.days.ago
    assert_equal fresh.id, search.last_matched_listing_id
  end

  test "respects the email preference but still advances the scan timestamp" do
    NotificationPreference.create!(user: @user, kind: "saved_search_match",
                                   in_app: true, email: false)
    search = search_for(name: "Daily CPUs")
    listing

    assert_no_enqueued_emails do
      SavedSearches::DigestJob.perform_now
    end

    assert search.reload.last_notified_at.present?
  end

  test "searches with no new matches do not send an email but are marked as evaluated" do
    search = search_for(name: "Quiet CPUs")

    assert_no_enqueued_emails do
      SavedSearches::DigestJob.perform_now
    end

    assert search.reload.last_notified_at.present?
    assert_nil search.last_matched_listing_id
  end

  test "email_alerts false excludes the search from the digest" do
    search = search_for(name: "Muted CPUs", email_alerts: false)
    listing

    assert_no_enqueued_emails do
      SavedSearches::DigestJob.perform_now
    end

    assert_nil search.reload.last_notified_at
  end
end
