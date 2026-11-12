# frozen_string_literal: true

module Payments
  # Prepares the Stripe objects needed by the mobile PaymentSheet: a Customer
  # stored on the user and a short-lived EphemeralKey. The PaymentIntent itself
  # is created by Checkouts::Start, exactly like the web checkout.
  class MobileSetup
    Result = Struct.new(:success, :publishable_key, :customer_id,
                        :ephemeral_key_secret, :error, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(user:, gateway: Payments.gateway)
      @user = user
      @gateway = gateway
    end

    def call
      customer_id = @user.stripe_customer_id.presence
      if customer_id.blank?
        customer = @gateway.create_customer(user: @user)
        return failure(customer.error) unless customer.success?

        customer_id = customer.customer_id
        @user.update_columns(stripe_customer_id: customer_id, updated_at: Time.current)
      end

      key = @gateway.create_ephemeral_key(customer_id: customer_id)
      return failure(key.error) unless key.success?

      Result.new(
        success: true,
        publishable_key: Payments.stripe_publishable_key.presence || "pk_test_fake",
        customer_id: customer_id,
        ephemeral_key_secret: key.secret,
        error: nil
      )
    end

    private

    def failure(error)
      Result.new(success: false, error: error)
    end
  end
end
