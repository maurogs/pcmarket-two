# frozen_string_literal: true

require "test_helper"

class Payments::StripeGatewayTest < ActiveSupport::TestCase
  setup do
    @previous_api_key = Stripe.api_key
    Stripe.api_key = "sk_test_webmock"
    @buyer = users(:moderator)
    @store = stores(:confirmed_store)
    @store.update!(stripe_account_id: "acct_test_123")
    @checkout = Checkout.create!(buyer: @buyer, email: @buyer.email,
                                 shipping_address: default_address_attributes.stringify_keys,
                                 status: "pending", idempotency_key: "idem-test-123",
                                 payment_intent_id: "pi_test_123")
    @order = Order.create!(checkout: @checkout, buyer: @buyer, store: @store,
                           subtotal_cents: 10_000, shipping_cents: 0, commission_cents: 1_000,
                           total_cents: 10_000, currency: "EUR")
    @gateway = Payments::StripeGateway.new
  end

  teardown do
    Stripe.api_key = @previous_api_key
  end

  test "create_payment creates one PaymentIntent for the checkout" do
    stub = stub_request(:post, "https://api.stripe.com/v1/payment_intents")
           .with(
             body: hash_including(
               "amount" => "10000",
               "currency" => "eur",
               "automatic_payment_methods" => { "enabled" => "true" },
               "transfer_group" => @checkout.id.to_s,
               "metadata" => { "checkout_id" => @checkout.id.to_s }
             ),
             headers: { "Idempotency-Key" => "idem-test-123" }
           )
           .to_return(status: 200,
                      body: { id: "pi_stripe_123", client_secret: "pi_stripe_123_secret" }.to_json,
                      headers: { "Content-Type" => "application/json" })

    result = @gateway.create_payment(checkout: @checkout)

    assert result.success?
    assert_equal "pi_stripe_123", result.payment_intent_id
    assert_equal "pi_stripe_123_secret", result.client_secret
    assert_requested stub
  end

  test "create_payment falls back to a generated idempotency key" do
    @checkout.update!(idempotency_key: nil)

    stub = stub_request(:post, "https://api.stripe.com/v1/payment_intents")
           .with(headers: { "Idempotency-Key" => "checkout_#{@checkout.id}" })
           .to_return(status: 200,
                      body: { id: "pi_stripe_123", client_secret: "secret" }.to_json,
                      headers: { "Content-Type" => "application/json" })

    assert @gateway.create_payment(checkout: @checkout).success?
    assert_requested stub
  end

  test "create_payment converts Stripe errors into a failure result" do
    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .to_return(status: 402, body: { error: { message: "card declined" } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @gateway.create_payment(checkout: @checkout)

    assert_not result.success?
    assert_equal "card declined", result.error
  end

  test "refund refunds the order amount on the checkout PaymentIntent" do
    stub = stub_request(:post, "https://api.stripe.com/v1/refunds")
           .with(
             body: hash_including(
               "payment_intent" => "pi_test_123",
               "amount" => "10000",
               "metadata" => { "order_id" => @order.id.to_s }
             ),
             headers: { "Idempotency-Key" => "refund_order_#{@order.id}" }
           )
           .to_return(status: 200, body: { id: "re_123" }.to_json,
                      headers: { "Content-Type" => "application/json" })

    result = @gateway.refund(order: @order)

    assert result.success?
    assert_equal "pi_test_123", result.payment_intent_id
    assert_requested stub
  end

  test "refund fails cleanly without a payment intent" do
    @checkout.update!(payment_intent_id: nil)

    result = @gateway.refund(order: @order)

    assert_not result.success?
    assert_equal "missing_payment_intent", result.error
  end

  test "transfer sends the net amount to the connected account" do
    stub = stub_request(:post, "https://api.stripe.com/v1/transfers")
           .with(
             body: hash_including(
               "amount" => "9000",
               "currency" => "eur",
               "destination" => "acct_test_123",
               "transfer_group" => @checkout.id.to_s,
               "metadata" => { "order_id" => @order.id.to_s }
             ),
             headers: { "Idempotency-Key" => "transfer_order_#{@order.id}" }
           )
           .to_return(status: 200, body: { id: "tr_123" }.to_json,
                      headers: { "Content-Type" => "application/json" })

    result = @gateway.transfer(order: @order)

    assert result.success?
    assert_equal "tr_123", result.transfer_id
    assert_requested stub
  end

  test "transfer fails cleanly when the store has no connected account" do
    @store.update!(stripe_account_id: nil)

    result = @gateway.transfer(order: @order)

    assert_not result.success?
    assert_equal "missing_stripe_account", result.error
  end
end
