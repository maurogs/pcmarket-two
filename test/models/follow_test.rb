# frozen_string_literal: true

require "test_helper"

class FollowTest < ActiveSupport::TestCase
  setup do
    @follower = users(:moderator)
    @store = stores(:confirmed_store)
  end

  test "a user can follow a store only once" do
    Follow.create!(follower: @follower, store: @store)
    duplicate = Follow.new(follower: @follower, store: @store)

    assert_not duplicate.valid?
    assert duplicate.errors[:store_id].any?
  end

  test "the store counter cache follows create and destroy" do
    assert_equal 0, @store.reload.followers_count

    follow = Follow.create!(follower: @follower, store: @store)
    assert_equal 1, @store.reload.followers_count

    follow.destroy!
    assert_equal 0, @store.reload.followers_count
  end

  test "destroying a follower removes their follows" do
    follow = Follow.create!(follower: @follower, store: @store)

    assert_difference -> { Follow.count }, -1 do
      @follower.destroy!
    end
    assert_not Follow.exists?(follow.id)
  end

  test "recent orders follows newest first" do
    older = Follow.create!(follower: @follower, store: @store)
    newer = Follow.create!(follower: users(:admin), store: stores(:suspended_store))
    older.update_columns(created_at: 2.days.ago)

    assert_equal [ newer.id, older.id ], Follow.recent.pluck(:id)
  end
end
