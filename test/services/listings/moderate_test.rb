# frozen_string_literal: true

require "test_helper"

class Listings::ModerateTest < ActiveSupport::TestCase
  test "approve! publishes the listing and writes a moderation log" do
    listing = listings(:pending_gpu)

    moderation = Listings::Moderate.new(listing: listing,
                                        moderator: users(:admin)).approve!

    assert_equal "published", listing.reload.status
    assert listing.published_at.present?
    assert_equal "approved", moderation.action
    assert_equal users(:admin), moderation.moderator
    assert_equal listing, moderation.listing
  end

  test "reject! rejects the listing and logs the reason" do
    listing = listings(:pending_gpu)

    moderation = Listings::Moderate.new(listing: listing,
                                        moderator: users(:admin),
                                        reason: "Blurry photos").reject!

    assert_equal "rejected", listing.reload.status
    assert_equal "Blurry photos", listing.rejection_reason
    assert_equal "rejected", moderation.action
    assert_equal "Blurry photos", moderation.reason
  end

  test "reject! refuses to run without a reason" do
    assert_raises(ArgumentError) do
      Listings::Moderate.new(listing: listings(:pending_gpu),
                             moderator: users(:admin)).reject!
    end

    assert_equal "pending_review", listings(:pending_gpu).reload.status
  end
end
