# frozen_string_literal: true

module Payments
  # Deterministic gateway used in development and tests. The checkout page
  # simulates a successful capture; tests can instantiate it with failure: true
  # to exercise declined payments.
  class FakeGateway < Gateway
    def initialize(failure: false)
      @failure = failure
    end

    def create_payment(checkout:)
      return Result.new(success: false, payment_intent_id: nil, error: "card_declined") if @failure

      Result.new(success: true, payment_intent_id: "fake_pi_#{SecureRandom.hex(10)}", error: nil)
    end

    def refund(order:)
      Result.new(success: true, payment_intent_id: order.checkout.payment_intent_id, error: nil)
    end
  end
end
