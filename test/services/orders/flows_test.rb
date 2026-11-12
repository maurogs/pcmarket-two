# frozen_string_literal: true

require "test_helper"

class Orders::FlowsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @listing = listings(:published_gpu)
  end

  def paid_order(listing: @listing)
    cart = build_cart(user: @buyer, listings: [ listing ])
    result = Checkouts::Start.new(
      cart: cart,
      buyer: @buyer,
      params: checkout_params(fulfilment: { @store.id.to_s => "shipping" }),
      gateway: Payments::FakeGateway.new
    ).call
    assert result.success?
    Checkouts::Complete.new(checkout: result.checkout, cart: cart).call
    clear_enqueued_jobs
    order = result.checkout.orders.first
    assert order.paid?, "expected order to be paid, got #{order.status}"
    order
  end

  test "the seller ships a paid order with tracking and the buyer is emailed" do
    order = paid_order
    assert_equal @seller.id, order.store.user_id

    assert Orders::Ship.new(order: order, actor: @seller,
                            carrier: "seur", tracking_number: "SEUR123").call

    assert order.reload.shipped?
    assert order.shipped_at.present?
    assert_equal "seur", order.tracking_carrier
    assert_equal "SEUR123", order.tracking_number
    assert_enqueued_email_with OrderMailer, :order_shipped, args: [ order ]
  end

  test "a shipping order cannot be shipped without carrier and tracking" do
    order = paid_order

    assert_not Orders::Ship.new(order: order, actor: @seller).call
    assert order.reload.paid?
  end

  test "local pickup orders need no tracking" do
    pickup = create_listing!(store: @store, seller: @seller, title: "Pickup GPU",
                             shipping_mode: "local_pickup")
    order = paid_order(listing: pickup)

    assert Orders::Ship.new(order: order, actor: @seller).call
    assert order.reload.shipped?
  end

  test "buyers cannot ship and sellers cannot confirm delivery" do
    order = paid_order

    assert_not Orders::Ship.new(order: order, actor: @buyer,
                                carrier: "seur", tracking_number: "SEUR123").call
    assert_not Orders::ConfirmDelivery.new(order: order, actor: @seller).call
  end

  test "the buyer confirms delivery, starts buyer protection and schedules auto-completion" do
    order = paid_order
    Orders::Ship.new(order: order, actor: @seller, carrier: "seur", tracking_number: "SEUR123").call
    clear_enqueued_jobs

    assert Orders::ConfirmDelivery.new(order: order, actor: @buyer).call

    order.reload
    assert order.delivered?
    assert order.delivered_at.present?
    assert_in_delta 2.days.from_now, order.buyer_protection_ends_at, 5.seconds
    assert_enqueued_email_with OrderMailer, :delivery_confirmed, args: [ order ]
    assert_enqueued_with job: AutoCompleteOrderJob
  end

  test "the auto-complete job completes a delivered order" do
    order = paid_order
    Orders::Ship.new(order: order, actor: @seller, carrier: "seur", tracking_number: "SEUR123").call
    Orders::ConfirmDelivery.new(order: order, actor: @buyer).call

    AutoCompleteOrderJob.perform_now(order)

    assert order.reload.completed?
    assert order.completed_at.present?
  end

  test "cancelling before shipping refunds, restocks and emails the counterpart" do
    order = paid_order

    assert Orders::Cancel.new(order: order, actor: @buyer,
                              gateway: Payments::FakeGateway.new).call

    assert order.reload.cancelled?
    assert_equal "published", @listing.reload.status
    assert_equal 1, @listing.quantity
    assert_enqueued_emails 1
  end

  test "orders cannot be cancelled after shipping" do
    order = paid_order
    Orders::Ship.new(order: order, actor: @seller, carrier: "seur", tracking_number: "SEUR123").call

    assert_not Orders::Cancel.new(order: order, actor: @buyer,
                                  gateway: Payments::FakeGateway.new).call
    assert order.reload.shipped?
  end

  test "cancelling a paid order asks the gateway for a refund" do
    order = paid_order
    gateway = Class.new do
      attr_reader :refunded_order

      def refund(order:)
        @refunded_order = order
        Payments::Gateway::Result.new(success: true)
      end
    end.new

    assert Orders::Cancel.new(order: order, actor: @buyer, gateway: gateway).call

    assert_equal order, gateway.refunded_order
    assert order.reload.cancelled?
    assert_equal "published", @listing.reload.status
  end
end
