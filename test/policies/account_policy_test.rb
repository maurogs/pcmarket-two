# frozen_string_literal: true

require "test_helper"

class AccountPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:confirmed)
    @other = users(:moderator)
  end

  test "only the account owner can manage the account" do
    policy = AccountPolicy.new(@user, @user)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?
    assert policy.export?

    other_policy = AccountPolicy.new(@other, @user)
    assert_not other_policy.show?
    assert_not other_policy.update?
    assert_not other_policy.destroy?
  end

  test "anonymous users cannot manage an account" do
    policy = AccountPolicy.new(nil, @user)

    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
