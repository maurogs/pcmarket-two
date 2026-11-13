# frozen_string_literal: true

require "test_helper"

class OrderPolicyTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @other = users(:seller_two)
    checkout = Checkout.create!(buyer: @buyer, email: @buyer.email,
                                shipping_address: default_address_attributes.stringify_keys)
    @order = Order.create!(checkout: checkout, buyer: @buyer, store: stores(:confirmed_store),
                           subtotal_cents: 10_000, shipping_cents: 0, commission_cents: 0,
                           total_cents: 10_000, currency: "EUR")
  end

  test "buyers and sellers can view an order but other users cannot" do
    assert OrderPolicy.new(@buyer, @order).show?
    assert OrderPolicy.new(@seller, @order).show?
    assert_not OrderPolicy.new(@other, @order).show?
  end

  test "only the buyer can confirm delivery" do
    @order.pay!
    @order.update!(tracking_carrier: "seur", tracking_number: "SEUR123")
    @order.ship!

    assert OrderPolicy.new(@buyer, @order).confirm_delivery?
    assert_not OrderPolicy.new(@seller, @order).confirm_delivery?
  end

  test "buyer and seller can cancel before shipping, but not after" do
    assert OrderPolicy.new(@buyer, @order).cancel?
    assert OrderPolicy.new(@seller, @order).cancel?
    assert_not OrderPolicy.new(@other, @order).cancel?

    @order.pay!
    @order.update!(tracking_carrier: "seur", tracking_number: "SEUR123")
    @order.ship!

    assert_not OrderPolicy.new(@buyer, @order).cancel?
  end

  test "the seller policy only exposes its own sales" do
    assert Sell::OrderPolicy.new(@seller, @order).show?
    assert_not Sell::OrderPolicy.new(@seller, @order).ship?
    assert_not Sell::OrderPolicy.new(@buyer, @order).show?
    assert_not Sell::OrderPolicy.new(@other, @order).show?
    assert Sell::OrderPolicy.new(@seller, @order).index?
  end

  test "the buyer policy scope only returns the buyer's orders" do
    scope = OrderPolicy::Scope.new(@buyer, Order.all).resolve

    assert_includes scope, @order
    assert_not_includes OrderPolicy::Scope.new(@other, Order.all).resolve, @order
  end
end
