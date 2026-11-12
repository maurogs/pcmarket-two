# frozen_string_literal: true

require "test_helper"

class Favourites::PriceDropJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @seller = users(:confirmed)
    @listing = create_listing!(store: stores(:confirmed_store), seller: @seller,
                               price_cents: 10_000)
    @buyer = users(:moderator)
    @second_buyer = users(:admin)
    Favourite.create!(user: @buyer, listing: @listing)
    Favourite.create!(user: @second_buyer, listing: @listing)
    clear_enqueued_jobs
    clear_enqueued_jobs
  end

  test "enqueues a job when the price drops but not when it rises" do
    assert_enqueued_with(job: Favourites::PriceDropJob, args: [ @listing.id, 10_000, 8_000 ]) do
      @listing.update!(price_cents: 8_000)
    end

    clear_enqueued_jobs

    assert_no_enqueued_jobs only: Favourites::PriceDropJob do
      @listing.update!(price_cents: 9_000)
    end
  end

  test "creates one notification per favouriter and one email per opted-in user" do
    NotificationPreference.create!(user: @second_buyer, kind: "price_drop",
                                   in_app: true, email: false)

    assert_difference -> { Notification.where(kind: "price_drop").count }, 2 do
      assert_enqueued_emails 1 do
        Favourites::PriceDropJob.perform_now(@listing.id, 10_000, 8_000)
      end
    end

    notification = Notification.find_by(recipient: @buyer, kind: "price_drop")
    assert notification.present?
    assert_equal 8_000, notification.params["price_cents"]
    assert_equal 10_000, notification.params["previous_price_cents"]
    assert_equal @listing, notification.notifiable
  end

  test "respects the in-app preference" do
    NotificationPreference.create!(user: @buyer, kind: "price_drop",
                                   in_app: false, email: true)

    assert_difference -> { Notification.where(kind: "price_drop").count }, 1 do
      Favourites::PriceDropJob.perform_now(@listing.id, 10_000, 8_000)
    end

    assert_not Notification.exists?(recipient: @buyer, kind: "price_drop")
  end

  test "does not email when the listing is no longer publicly visible" do
    @listing.update!(status: "reserved")

    assert_difference -> { Notification.where(kind: "price_drop").count }, 2 do
      assert_no_enqueued_emails do
        Favourites::PriceDropJob.perform_now(@listing.id, 10_000, 8_000)
      end
    end
  end
end
