# frozen_string_literal: true

module Payments
  # Deterministic gateway used in development and tests without Stripe keys. The
  # checkout page simulates a successful capture; tests can instantiate it with
  # failure: true to exercise declined payments.
  class FakeGateway < Gateway
    def initialize(failure: false, mobile: false)
      @failure = failure
      @mobile = mobile
    end

    def create_payment(checkout:)
      return failed_payment if @failure

      Result.new(success: true,
                 payment_intent_id: "fake_pi_#{SecureRandom.hex(10)}",
                 client_secret: @mobile ? "fake_pi_secret_#{SecureRandom.hex(12)}" : nil,
                 error: nil)
    end

    def create_customer(user:)
      CustomerResult.new(success: true, customer_id: "fake_cus_#{user.id}", error: nil)
    end

    def create_ephemeral_key(customer_id:)
      EphemeralKeyResult.new(success: true,
                             secret: "fake_ek_#{customer_id}_#{SecureRandom.hex(6)}",
                             error: nil)
    end

    def refund(order:, amount_cents: nil)
      Result.new(success: true,
                 payment_intent_id: order.checkout.payment_intent_id,
                 error: nil)
    end

    def transfer(order:)
      Result.new(success: true, transfer_id: "fake_tr_#{SecureRandom.hex(10)}", error: nil)
    end

    private

    def failed_payment
      Result.new(success: false, payment_intent_id: nil, client_secret: nil,
                 error: "card_declined")
    end
  end
end
