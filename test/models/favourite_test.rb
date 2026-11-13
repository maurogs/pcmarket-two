# frozen_string_literal: true

require "test_helper"

class FavouriteTest < ActiveSupport::TestCase
  setup do
    @user = users(:moderator)
    @listing = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed))
  end

  test "a user can favourite a listing only once" do
    Favourite.create!(user: @user, listing: @listing)
    duplicate = Favourite.new(user: @user, listing: @listing)

    assert_not duplicate.valid?
    assert duplicate.errors[:listing_id].any?
  end

  test "the listing counter cache follows create and destroy" do
    assert_equal 0, @listing.reload.favorites_count

    favourite = Favourite.create!(user: @user, listing: @listing)
    assert_equal 1, @listing.reload.favorites_count

    favourite.destroy!
    assert_equal 0, @listing.reload.favorites_count
  end

  test "destroying a listing destroys its favourites" do
    Favourite.create!(user: @user, listing: @listing)

    assert_difference -> { Favourite.count }, -1 do
      @listing.destroy!
    end
  end

  test "destroying a user destroys their favourites" do
    Favourite.create!(user: @user, listing: @listing)

    assert_difference -> { Favourite.count }, -1 do
      @user.destroy!
    end
  end

  test "recent orders favourites newest first" do
    older = Favourite.create!(user: @user, listing: @listing)
    other = create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                            title: "Second favourite")
    newer = Favourite.create!(user: users(:admin), listing: other)
    older.update_columns(created_at: 2.days.ago)

    assert_equal [ newer.id, older.id ], Favourite.recent.pluck(:id)
  end
end
