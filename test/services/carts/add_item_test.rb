# frozen_string_literal: true

require "test_helper"

class Carts::AddItemTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @listing = listings(:published_gpu)
    @cart = Cart.create!(user: @buyer)
  end

  teardown do
    Flipper.disable(:guest_checkout)
  end

  test "adds an available listing to the cart" do
    result = Carts::AddItem.new(cart: @cart, listing: @listing).call

    assert result.success?
    assert_equal 1, @cart.items.count
    assert_equal 1, @cart.items.first.quantity
  end

  test "accumulates quantity for an existing item" do
    @listing.update!(quantity: 3)

    Carts::AddItem.new(cart: @cart, listing: @listing).call
    result = Carts::AddItem.new(cart: @cart, listing: @listing).call

    assert result.success?
    assert_equal 2, @cart.items.first.reload.quantity
  end

  test "refuses to buy your own listing" do
    cart = Cart.create!(user: users(:confirmed))

    result = Carts::AddItem.new(cart: cart, listing: @listing).call

    assert_not result.success?
    assert_equal [ I18n.t("cart.errors.own_listing") ], result.errors
  end

  test "refuses unavailable listings" do
    @listing.update!(status: "draft")

    result = Carts::AddItem.new(cart: @cart, listing: @listing).call

    assert_not result.success?
    assert_equal [ I18n.t("cart.errors.unavailable") ], result.errors
  end

  test "refuses listings from sellers on holiday" do
    @listing.store.update!(vacation_mode: true)

    result = Carts::AddItem.new(cart: @cart, listing: @listing).call

    assert_not result.success?
    assert_equal [ I18n.t("cart.errors.store_vacation") ], result.errors
  end

  test "refuses quantities above the available stock" do
    result = Carts::AddItem.new(cart: @cart, listing: @listing, quantity: 2).call

    assert_not result.success?
    assert_equal [ I18n.t("cart.errors.insufficient_stock") ], result.errors
  end

  test "guests can add items only when guest checkout is enabled" do
    guest_cart = Cart.create!
    listing = listings(:amd_gpu)

    result = Carts::AddItem.new(cart: guest_cart, listing: listing).call
    assert_not result.success?
    assert_equal [ I18n.t("cart.errors.guest_disabled") ], result.errors

    Flipper.enable(:guest_checkout)
    result = Carts::AddItem.new(cart: guest_cart, listing: listing).call
    assert result.success?
    assert_equal 1, guest_cart.items.count
  end
end
