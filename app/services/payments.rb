# frozen_string_literal: true

module Payments
  # The payment capture boundary. Phase 4b will provide a Stripe-backed
  # implementation of this interface; development, test and Phase 4a use the
  # deterministic fake gateway below.
  def self.gateway(failure: false)
    raise NotImplementedError, "Configure the Stripe gateway in Phase 4b" if Rails.env.production?

    FakeGateway.new(failure: failure)
  end
end
