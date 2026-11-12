# frozen_string_literal: true

require "test_helper"

class AdminListingPolicyTest < ActiveSupport::TestCase
  test "moderators can moderate listings" do
    policy = Admin::ListingPolicy.new(users(:moderator), listings(:pending_gpu))

    assert policy.index?
    assert policy.show?
    assert policy.update?
    assert policy.moderate?
  end

  test "admins can moderate listings" do
    policy = Admin::ListingPolicy.new(users(:admin), listings(:pending_gpu))

    assert policy.index?
    assert policy.show?
    assert policy.update?
    assert policy.moderate?
  end

  test "regular users cannot moderate listings" do
    policy = Admin::ListingPolicy.new(users(:confirmed), listings(:pending_gpu))

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.moderate?
  end

  test "anonymous visitors cannot moderate listings" do
    policy = Admin::ListingPolicy.new(nil, listings(:pending_gpu))

    assert_not policy.moderate?
  end
end
