# frozen_string_literal: true

require "test_helper"

class FollowsTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @listing = create_listing!(store: @store, seller: @seller, title: "Followable listing")
  end

  test "a buyer follows and unfollows the seller from the listing card" do
    sign_in @buyer

    get listing_path(@listing, locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("follows.button.follow", locale: :en)

    assert_difference -> { Follow.count }, 1 do
      post store_follow_path(@store, locale: :en)
    end

    assert_redirected_to wishlist_path(tab: "following", locale: :en)
    assert_equal 1, @store.reload.followers_count
    assert_equal 1, @buyer.follows.count

    get listing_path(@listing, locale: :en)
    assert_includes response.body, I18n.t("follows.button.following", locale: :en)

    assert_difference -> { Follow.count }, -1 do
      delete store_follow_path(@store, locale: :en)
    end

    assert_redirected_to wishlist_path(tab: "following", locale: :en)
    assert_equal 0, @store.reload.followers_count
  end

  test "the seller does not see a follow button on their own store" do
    sign_in @seller

    get listing_path(@listing, locale: :en)

    assert_response :success
    assert_not_includes response.body, I18n.t("follows.button.follow", locale: :en)
    assert_not_includes response.body, I18n.t("follows.button.following", locale: :en)
  end
end
