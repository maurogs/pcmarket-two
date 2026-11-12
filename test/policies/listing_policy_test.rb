# frozen_string_literal: true

require "test_helper"

class ListingPolicyTest < ActiveSupport::TestCase
  test "the owner can edit update and destroy a listing" do
    policy = ListingPolicy.new(users(:confirmed), listings(:draft_gpu))

    assert policy.edit?
    assert policy.update?
    assert policy.destroy?
  end

  test "another user cannot edit update or destroy the listing" do
    policy = ListingPolicy.new(users(:seller_two), listings(:draft_gpu))

    assert_not policy.edit?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "a confirmed user with an active store can create listings" do
    assert ListingPolicy.new(users(:confirmed), Listing.new).create?
  end

  test "a banned user cannot create listings" do
    assert_not ListingPolicy.new(users(:banned), Listing.new).create?
  end

  test "an unconfirmed user cannot create listings" do
    user = User.new(username: "pending_user", email: "pending@example.com",
                    password: "Password123!", confirmed_at: nil)

    assert_not ListingPolicy.new(user, Listing.new).create?
  end

  test "a user with a suspended store cannot create listings" do
    assert_not ListingPolicy.new(users(:seller_two), Listing.new).create?
  end
end
