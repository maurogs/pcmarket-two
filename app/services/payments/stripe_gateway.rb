# frozen_string_literal: true

module Payments
  # Stripe implementation of the payment boundary. One PaymentIntent covers the
  # whole checkout; refunds and Connect transfers are issued per order.
  class StripeGateway < Gateway
    def create_payment(checkout:)
      intent = Stripe::PaymentIntent.create(
        {
          amount: checkout.total_cents,
          currency: currency_for(checkout),
          automatic_payment_methods: { enabled: true },
          transfer_group: checkout.id.to_s,
          metadata: { checkout_id: checkout.id }
        },
        idempotency_key: checkout.idempotency_key.presence || "checkout_#{checkout.id}"
      )

      Result.new(success: true,
                 payment_intent_id: intent.id,
                 client_secret: intent.client_secret,
                 error: nil)
    rescue Stripe::StripeError => e
      Result.new(success: false, error: e.message)
    end

    def refund(order:, amount_cents: nil)
      payment_intent_id = order.checkout.payment_intent_id
      return Result.new(success: false, error: "missing_payment_intent") if payment_intent_id.blank?

      amount = amount_cents.presence || order.total_cents
      idempotency_key = if amount_cents.present?
        "partial_refund_order_#{order.id}_#{amount}"
      else
        "refund_order_#{order.id}"
      end

      Stripe::Refund.create(
        {
          payment_intent: payment_intent_id,
          amount: amount,
          metadata: { order_id: order.id }
        },
        idempotency_key: idempotency_key
      )

      Result.new(success: true, payment_intent_id: payment_intent_id, error: nil)
    rescue Stripe::StripeError => e
      Result.new(success: false, error: e.message)
    end

    def transfer(order:)
      destination = order.store.stripe_account_id
      return Result.new(success: false, error: "missing_stripe_account") if destination.blank?

      transfer = Stripe::Transfer.create(
        {
          amount: transfer_amount_for(order),
          currency: currency_for_order(order),
          destination: destination,
          transfer_group: order.checkout_id.to_s,
          metadata: { order_id: order.id }
        },
        idempotency_key: "transfer_order_#{order.id}"
      )

      Result.new(success: true, transfer_id: transfer.id, error: nil)
    rescue Stripe::StripeError => e
      Result.new(success: false, error: e.message)
    end

    private

    def transfer_amount_for(order)
      [ order.total_cents.to_i - order.commission_cents.to_i, 0 ].max
    end

    def currency_for(checkout)
      checkout.orders.first&.currency.presence&.downcase || "eur"
    end

    def currency_for_order(order)
      order.currency.presence&.downcase || "eur"
    end
  end
end
