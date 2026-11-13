# frozen_string_literal: true

require "test_helper"

class Carts::MergeTest < ActiveSupport::TestCase
  setup do
    @user = users(:moderator)
    @guest_cart = Cart.create!
    @user_cart = Cart.create!(user: @user)
  end

  teardown do
    Flipper.disable(:guest_checkout)
  end

  test "moves guest items into the user cart and destroys the guest cart" do
    Flipper.enable(:guest_checkout)
    @guest_cart.items.create!(listing: listings(:published_gpu), quantity: 1)

    merged = Carts::Merge.new(guest_cart: @guest_cart, user_cart: @user_cart).call

    assert_equal @user_cart, merged
    assert_equal [ listings(:published_gpu).id ], @user_cart.items.map(&:listing_id)
    assert_not Cart.exists?(@guest_cart.id)
  end

  test "adds to an existing user item instead of duplicating it" do
    Flipper.enable(:guest_checkout)
    listing = listings(:published_gpu)
    listing.update!(quantity: 3)
    @guest_cart.items.create!(listing: listing, quantity: 1)
    @user_cart.items.create!(listing: listing, quantity: 1)

    Carts::Merge.new(guest_cart: @guest_cart, user_cart: @user_cart).call

    assert_equal 2, @user_cart.items.first.reload.quantity
    assert_equal 1, @user_cart.items.count
  end

  test "skips guest items that are no longer purchasable" do
    Flipper.enable(:guest_checkout)
    listing = listings(:published_gpu)
    @guest_cart.items.create!(listing: listing, quantity: 1)
    listing.update!(status: "draft")

    Carts::Merge.new(guest_cart: @guest_cart, user_cart: @user_cart).call

    assert_empty @user_cart.items.reload
  end
end
