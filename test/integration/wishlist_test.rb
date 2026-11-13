# frozen_string_literal: true

require "test_helper"

class WishlistTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @listing = create_listing!(store: @store, seller: @seller, title: "Wishlist listing")
  end

  test "the wishlist requires authentication" do
    get wishlist_path(locale: :en)

    assert_redirected_to new_user_session_path(locale: :en)
  end

  test "shows the user's favourites" do
    Favourite.create!(user: @buyer, listing: @listing)
    sign_in @buyer

    get wishlist_path(locale: :en)

    assert_response :success
    assert_includes response.body, @listing.title
    assert_includes response.body, I18n.t("wishlist.favourites.move_to_basket", locale: :en)
  end

  test "greyed-out favourites show the sold and unavailable badges" do
    Favourite.create!(user: @buyer, listing: listings(:sold_gpu))
    Favourite.create!(user: @buyer, listing: listings(:pending_gpu))
    sign_in @buyer

    get wishlist_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("wishlist.sold", locale: :en)
    assert_includes response.body, I18n.t("wishlist.unavailable", locale: :en)
    assert_select "li.opacity-60", minimum: 2
  end

  test "moving a favourite to the basket creates a cart item" do
    Favourite.create!(user: @buyer, listing: @listing)
    sign_in @buyer

    assert_difference -> { CartItem.count }, 1 do
      post cart_items_path(locale: :en),
           params: { listing_id: @listing.id, quantity: 1 }
    end

    assert_redirected_to cart_path(locale: :en)
    assert CartItem.exists?(cart: Cart.find_by(user: @buyer), listing: @listing)
  end

  test "the following tab lists followed stores and unfollowing works" do
    follow = Follow.create!(follower: @buyer, store: @store)
    sign_in @buyer

    get wishlist_path(tab: "following", locale: :en)

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(@store.name)
    assert_includes response.body,
                    I18n.t("wishlist.following.followers_count", count: 1, locale: :en)

    assert_difference -> { Follow.count }, -1 do
      delete store_follow_path(@store, locale: :en),
             headers: { "Referer" => wishlist_path(tab: "following", locale: :en) }
    end

    assert_redirected_to wishlist_path(tab: "following", locale: :en)
    assert_not Follow.exists?(follow.id)
    assert_equal 0, @store.reload.followers_count
  end
end
