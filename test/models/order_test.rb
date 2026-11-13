# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @checkout = Checkout.create!(
      buyer: @buyer,
      email: @buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
  end

  def build_order(store: stores(:confirmed_store), **attrs)
    Order.create!({
      checkout: @checkout,
      buyer: @buyer,
      store: store,
      subtotal_cents: 10_000,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 10_000,
      currency: "EUR"
    }.merge(attrs))
  end

  test "assigns a unique human-readable number after creation" do
    order = build_order
    other_checkout = Checkout.create!(buyer: @buyer, email: @buyer.email,
                                      shipping_address: default_address_attributes.stringify_keys)
    other = Order.create!(checkout: other_checkout, buyer: @buyer, store: stores(:suspended_store),
                          subtotal_cents: 5000, shipping_cents: 0, commission_cents: 0,
                          total_cents: 5000, currency: "EUR")

    assert_match(/\APCM-\d{4}-\d{6,}\z/, order.reload.number)
    assert_match(/\APCM-\d{4}-\d{6,}\z/, other.reload.number)
    assert_not_equal order.number, other.number
  end

  test "commission is zero unless both the flag and the setting are enabled" do
    assert_equal 0, Order.commission_for(10_000)

    Flipper.enable(:commissions)
    assert_equal 0, Order.commission_for(10_000)

    Setting.set(:commission_enabled, true)
    Setting.set(:commission_percent, 5.0)
    assert_equal 500, Order.commission_for(10_000)
  ensure
    Flipper.disable(:commissions)
    Setting.set(:commission_enabled, false)
  end

  test "starts pending payment and moves through the paid state" do
    order = build_order

    assert order.pending_payment?
    assert order.pay!
    assert order.paid?
    assert order.paid_at.present?
  end

  test "a shipped order requires carrier and tracking information" do
    order = build_order
    order.pay!

    assert_not order.ship!
    assert order.paid?

    order.tracking_carrier = "seur"
    order.tracking_number = "SEUR123"
    assert order.ship!
    assert order.shipped?
  end

  test "local pickup orders can be shipped without tracking" do
    order = build_order(fulfilment: "local_pickup")
    order.pay!

    assert order.ship!
    assert order.shipped?
  end

  test "confirming delivery opens the buyer protection window" do
    order = build_order
    order.pay!
    order.update!(tracking_carrier: "seur", tracking_number: "SEUR123")
    order.ship!

    Setting.set(:buyer_protection_days, 3)
    order.confirm_delivery!

    assert order.delivered?
    assert order.delivered_at.present?
    assert_in_delta 3.days.from_now, order.buyer_protection_ends_at, 5.seconds
  ensure
    Setting.set(:buyer_protection_days, 2)
  end
end
