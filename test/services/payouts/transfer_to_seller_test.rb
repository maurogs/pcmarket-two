# frozen_string_literal: true

require "test_helper"

class Payouts::TransferToSellerTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @store = stores(:confirmed_store)
    @store.update!(stripe_account_id: "acct_payout_123")
    @checkout = Checkout.create!(
      buyer: @buyer,
      email: @buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
  end

  test "transfers the order total minus commission and marks the payout paid" do
    order = completed_order(total_cents: 10_000, commission_cents: 1_000)

    assert Payouts::TransferToSeller.new(order: order, gateway: Payments::FakeGateway.new).call

    payout = order.reload.payout
    assert payout.paid?
    assert_equal 9_000, payout.amount_cents
    assert_match(/\Afake_tr_/, payout.stripe_transfer_id)
  end

  test "transfers the full total when there is no commission" do
    order = completed_order(total_cents: 10_000, commission_cents: 0)

    assert Payouts::TransferToSeller.new(order: order, gateway: Payments::FakeGateway.new).call

    assert_equal 10_000, order.reload.payout.amount_cents
  end

  test "is idempotent and never transfers the same order twice" do
    order = completed_order(total_cents: 10_000, commission_cents: 1_000)
    calls = 0
    gateway = Object.new
    gateway.define_singleton_method(:transfer) do |order:|
      calls += 1
      Payments::Gateway::Result.new(success: true, transfer_id: "tr_once")
    end

    2.times { Payouts::TransferToSeller.new(order: order, gateway: gateway).call }

    assert_equal 1, calls
    assert_equal 1, Payout.where(order: order).count
    assert_equal "tr_once", order.reload.payout.stripe_transfer_id
  end

  test "records a failed transfer without touching the order" do
    order = completed_order(total_cents: 10_000, commission_cents: 0)
    gateway = Object.new
    gateway.define_singleton_method(:transfer) do |order:|
      Payments::Gateway::Result.new(success: false, error: "insufficient_funds")
    end

    assert_not Payouts::TransferToSeller.new(order: order, gateway: gateway).call

    payout = order.reload.payout
    assert payout.failed?
    assert_equal "insufficient_funds", payout.error
    assert order.completed?
  end

  test "does nothing until the order is completed" do
    order = completed_order(status: "delivered", total_cents: 10_000, commission_cents: 0)

    assert_not Payouts::TransferToSeller.new(order: order, gateway: Payments::FakeGateway.new).call
    assert_nil order.reload.payout
  end

  private

  def completed_order(status: "completed", total_cents:, commission_cents:)
    Order.create!(
      checkout: @checkout,
      buyer: @buyer,
      store: @store,
      status: status,
      completed_at: status == "completed" ? Time.current : nil,
      subtotal_cents: total_cents,
      shipping_cents: 0,
      commission_cents: commission_cents,
      total_cents: total_cents,
      currency: "EUR"
    )
  end
end
