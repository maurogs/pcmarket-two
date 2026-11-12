# frozen_string_literal: true

require "test_helper"

class StorePolicyTest < ActiveSupport::TestCase
  test "the owner can edit and update their store" do
    policy = StorePolicy.new(users(:confirmed), stores(:confirmed_store))

    assert policy.edit?
    assert policy.update?
  end

  test "another user cannot edit or update someone else's store" do
    policy = StorePolicy.new(users(:seller_two), stores(:confirmed_store))

    assert_not policy.edit?
    assert_not policy.update?
  end

  test "a user without a store can create one" do
    assert StorePolicy.new(users(:admin), Store.new).create?
  end

  test "a user who already has a store cannot create another one" do
    assert_not StorePolicy.new(users(:confirmed), stores(:confirmed_store)).create?
  end
end
