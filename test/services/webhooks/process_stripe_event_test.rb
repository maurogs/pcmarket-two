# frozen_string_literal: true

require "test_helper"

class Webhooks::ProcessStripeEventTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @buyer = users(:moderator)
    @store = stores(:confirmed_store)
    @listing = listings(:published_gpu)
    ActionMailer::Base.deliveries.clear
  end

  test "payment_intent.succeeded completes the pending checkout" do
    checkout = start_checkout
    event = webhook_event("payment_intent.succeeded", object: intent_object(checkout))

    Webhooks::ProcessStripeEvent.new(event).call

    assert checkout.reload.paid?
    assert checkout.orders.first.paid?
    assert event.reload.processed?
    assert_nil event.error
  end

  test "payment_intent.succeeded clears the purchased lines from the buyer basket" do
    cart = build_cart(user: @buyer, listings: [ @listing ])
    checkout = start_checkout(cart: cart)
    event = webhook_event("payment_intent.succeeded", object: intent_object(checkout))

    Webhooks::ProcessStripeEvent.new(event).call

    assert checkout.reload.paid?
    assert checkout.orders.first.paid?
    assert_empty @buyer.cart.reload.items
  end

  test "payment_intent.payment_failed fails the checkout and releases stock" do
    checkout = start_checkout
    event = webhook_event("payment_intent.payment_failed", object: intent_object(checkout))

    Webhooks::ProcessStripeEvent.new(event).call

    assert checkout.reload.failed?
    assert_equal "cancelled", checkout.orders.first.status
    assert_equal "published", @listing.reload.status
    assert_equal 1, @listing.quantity
  end

  test "charge.refunded refunds the matching order" do
    order = paid_order
    event = webhook_event("charge.refunded",
                          object: {
                            payment_intent: order.checkout.payment_intent_id,
                            amount_refunded: order.total_cents,
                            metadata: { order_id: order.id }
                          })

    Webhooks::ProcessStripeEvent.new(event).call

    assert order.reload.refunded?
  end

  test "charge.dispute.created opens a dispute and emails every admin" do
    order = paid_order
    clear_enqueued_jobs
    event = webhook_event("charge.dispute.created",
                          object: { payment_intent: order.checkout.payment_intent_id })

    Webhooks::ProcessStripeEvent.new(event).call
    perform_enqueued_jobs

    assert order.reload.disputed?
    assert ActionMailer::Base.deliveries.any? { |mail| mail.to.include?(users(:admin).email) }
  end

  test "charge.dispute.created handles a completed order after the payout" do
    order = completed_order
    clear_enqueued_jobs
    event = webhook_event("charge.dispute.created",
                          object: { payment_intent: order.checkout.payment_intent_id })

    Webhooks::ProcessStripeEvent.new(event).call
    perform_enqueued_jobs

    assert order.reload.disputed?
    assert ActionMailer::Base.deliveries.any? { |mail| mail.to.include?(users(:admin).email) }
  end

  test "account.updated refreshes the Connect account status" do
    @store.update!(stripe_account_id: "acct_update_123")
    event = webhook_event("account.updated",
                          object: {
                            id: "acct_update_123",
                            payouts_enabled: true,
                            charges_enabled: true,
                            details_submitted: true,
                            requirements: { currently_due: [ "external_account" ] }
                          })

    Webhooks::ProcessStripeEvent.new(event).call

    @store.reload
    assert @store.payouts_enabled?
    assert @store.charges_enabled?
    assert @store.details_submitted?
    assert_equal [ "external_account" ], @store.requirements["currently_due"]
  end

  test "transfer.created marks the payout as paid" do
    order = completed_order
    payout = Payout.create!(order: order, store: @store, amount_cents: 9_000)
    event = webhook_event("transfer.created",
                          object: { id: "tr_123", metadata: { order_id: order.id } })

    Webhooks::ProcessStripeEvent.new(event).call

    payout.reload
    assert payout.paid?
    assert_equal "tr_123", payout.stripe_transfer_id
  end

  test "transfer.reversed marks the payout as failed" do
    order = completed_order
    payout = Payout.create!(order: order, store: @store, amount_cents: 9_000,
                            status: "paid", stripe_transfer_id: "tr_123")
    event = webhook_event("transfer.reversed",
                          object: { id: "tr_123", metadata: { order_id: order.id } })

    Webhooks::ProcessStripeEvent.new(event).call

    assert payout.reload.failed?
  end

  test "unknown event types are marked as processed without side effects" do
    event = webhook_event("customer.created", object: { id: "cus_123" })

    Webhooks::ProcessStripeEvent.new(event).call

    assert event.reload.processed?
  end

  test "an already processed event is ignored" do
    checkout = start_checkout
    event = webhook_event("payment_intent.succeeded", object: intent_object(checkout))
    Webhooks::ProcessStripeEvent.new(event).call
    processed_at = event.reload.processed_at

    Webhooks::ProcessStripeEvent.new(event).call

    assert_equal processed_at, event.reload.processed_at
  end

  test "a processing error is stored without marking the event as processed" do
    checkout = start_checkout
    event = webhook_event("payment_intent.succeeded", object: intent_object(checkout))
    with_stub(Checkouts::Complete, :new, ->(**) { raise "boom" }) do
      assert_raises(RuntimeError) { Webhooks::ProcessStripeEvent.new(event).call }
    end

    event.reload
    assert_not event.processed?
    assert_equal "boom", event.error
  end

  private

  def start_checkout(cart: build_cart(user: @buyer, listings: [ @listing ]))
    result = Checkouts::Start.new(
      cart: cart,
      buyer: @buyer,
      params: checkout_params(fulfilment: { @store.id.to_s => "shipping" }),
      gateway: Payments::FakeGateway.new
    ).call

    assert result.success?
    result.checkout
  end

  def paid_order
    checkout = start_checkout
    Checkouts::Complete.new(checkout: checkout).call
    checkout.orders.first.tap(&:reload)
  end

  def completed_order
    order = paid_order
    order.update!(status: "completed", completed_at: Time.current)
    order
  end

  def intent_object(checkout)
    { id: checkout.payment_intent_id, metadata: { checkout_id: checkout.id } }
  end

  def webhook_event(type, object:)
    WebhookEvent.create!(
      provider: "stripe",
      event_id: "evt_#{SecureRandom.hex(6)}",
      type: type,
      payload: { id: "evt_test", type: type, data: { object: object } }
    )
  end
end
