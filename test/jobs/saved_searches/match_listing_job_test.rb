# frozen_string_literal: true

require "test_helper"

class SavedSearches::MatchListingJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @user = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    clear_enqueued_jobs
    clear_enqueued_jobs
  end

  def search_for(**attrs)
    SavedSearch.create!({
      user: @user,
      name: "GPU watch",
      category: categories(:gpus),
      frequency: "instant",
      email_alerts: true,
      query_params: {}
    }.merge(attrs))
  end

  def gpu_listing(**attrs)
    create_listing!(**{
      store: @store,
      seller: @seller,
      category: categories(:nvidia),
      title: "Matching NVIDIA GPU",
      specs: { gpu_chipset: "nvidia" }
    }.merge(attrs))
  end

  test "an instant search creates a notification, sends an email and updates both timestamps" do
    search = search_for
    listing = gpu_listing

    assert_difference -> { Notification.where(kind: "saved_search_match").count }, 1 do
      assert_enqueued_emails 1 do
        SavedSearches::MatchListingJob.perform_now(listing.id)
      end
    end

    search.reload
    assert search.last_notified_at.present?
    assert_equal listing.id, search.last_matched_listing_id
  end

  test "a daily search notifies but sends no immediate email" do
    search = search_for(frequency: "daily")
    listing = gpu_listing

    assert_difference -> { Notification.where(kind: "saved_search_match").count }, 1 do
      assert_no_enqueued_emails do
        SavedSearches::MatchListingJob.perform_now(listing.id)
      end
    end

    search.reload
    assert_nil search.last_notified_at
    assert_equal listing.id, search.last_matched_listing_id
  end

  test "email_alerts false suppresses the instant email" do
    search = search_for(email_alerts: false)
    listing = gpu_listing

    assert_difference -> { Notification.where(kind: "saved_search_match").count }, 1 do
      assert_no_enqueued_emails do
        SavedSearches::MatchListingJob.perform_now(listing.id)
      end
    end

    search.reload
    assert_nil search.last_notified_at
    assert_equal listing.id, search.last_matched_listing_id
  end

  test "does not match a listing that is not publicly visible" do
    search = search_for
    draft = gpu_listing(status: "draft")

    assert_no_difference -> { Notification.where(kind: "saved_search_match").count } do
      assert_no_enqueued_emails do
        SavedSearches::MatchListingJob.perform_now(draft.id)
      end
    end

    assert_nil search.reload.last_matched_listing_id
  end
end
