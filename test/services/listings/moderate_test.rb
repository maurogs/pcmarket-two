# frozen_string_literal: true

require "test_helper"

class Listings::ModerateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    clear_enqueued_jobs
  end

  test "approve! publishes the listing, writes a moderation log and emails the seller" do
    listing = listings(:pending_gpu)

    moderation = Listings::Moderate.new(listing: listing,
                                        moderator: users(:admin)).approve!

    assert_equal "published", listing.reload.status
    assert listing.published_at.present?
    assert_equal "approved", moderation.action
    assert_equal users(:admin), moderation.moderator
    assert_equal listing, moderation.listing
    assert_enqueued_email_with ListingMailer, :approved, args: [ listing ]
  end

  test "reject! rejects the listing, logs the reason and emails the seller" do
    listing = listings(:pending_gpu)

    moderation = Listings::Moderate.new(listing: listing,
                                        moderator: users(:admin),
                                        reason: "Blurry photos").reject!

    assert_equal "rejected", listing.reload.status
    assert_equal "Blurry photos", listing.rejection_reason
    assert_equal "rejected", moderation.action
    assert_equal "Blurry photos", moderation.reason
    assert_enqueued_email_with ListingMailer, :rejected, args: [ listing ]
  end

  test "reject! refuses to run without a reason" do
    assert_raises(ArgumentError) do
      Listings::Moderate.new(listing: listings(:pending_gpu),
                             moderator: users(:admin)).reject!
    end

    assert_equal "pending_review", listings(:pending_gpu).reload.status
    assert_no_enqueued_emails
  end

  test "moderating the same listing twice logs once and emails once" do
    listing = listings(:pending_gpu)

    first = Listings::Moderate.new(listing: listing, moderator: users(:admin)).approve!
    second = Listings::Moderate.new(listing: listing, moderator: users(:moderator)).approve!

    assert first.present?
    assert_nil second
    assert_equal 1, ListingModeration.where(listing: listing).count
    assert_enqueued_emails 1
  end
end
