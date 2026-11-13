# frozen_string_literal: true

require "test_helper"

class Follows::NewListingJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @follower = users(:moderator)
    @second_follower = users(:admin)
    @follow = Follow.create!(follower: @follower, store: @store)
    clear_enqueued_jobs
    clear_enqueued_jobs
  end

  test "notifies followers in-app and never the seller" do
    Follow.create!(follower: @second_follower, store: @store)
    Follow.create!(follower: @seller, store: @store)
    listing = create_listing!(store: @store, seller: @seller, title: "New follower alert")

    assert_difference -> { Notification.where(kind: "followed_store_new_listing").count }, 2 do
      Follows::NewListingJob.perform_now(listing.id)
    end

    assert Notification.exists?(recipient: @follower, notifiable: listing)
    assert Notification.exists?(recipient: @second_follower, notifiable: listing)
    assert_not Notification.exists?(recipient: @seller, kind: "followed_store_new_listing")
  end

  test "sends one digest per follow and throttles it for 24 hours" do
    first = create_listing!(store: @store, seller: @seller, title: "First new listing")

    assert_enqueued_emails 1 do
      Follows::NewListingJob.perform_now(first.id)
    end
    notified_at = @follow.reload.last_notified_at
    assert notified_at.present?

    clear_enqueued_jobs
    second = create_listing!(store: @store, seller: @seller, title: "Second new listing")

    assert_no_enqueued_emails do
      Follows::NewListingJob.perform_now(second.id)
    end
    assert_equal notified_at, @follow.reload.last_notified_at

    clear_enqueued_jobs
    third = create_listing!(store: @store, seller: @seller, title: "Third new listing")

    travel 25.hours do
      assert_enqueued_emails 1 do
        Follows::NewListingJob.perform_now(third.id)
      end
    end
  end

  test "respects the email preference and leaves the timestamp empty" do
    NotificationPreference.create!(user: @follower, kind: "followed_store_new_listing",
                                   in_app: true, email: false)
    listing = create_listing!(store: @store, seller: @seller, title: "Email opt-out listing")

    assert_difference -> { Notification.where(kind: "followed_store_new_listing").count }, 1 do
      assert_no_enqueued_emails do
        Follows::NewListingJob.perform_now(listing.id)
      end
    end

    assert_nil @follow.reload.last_notified_at
  end
end
