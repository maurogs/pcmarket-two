# frozen_string_literal: true

module Payments
  class Gateway
    Result = Struct.new(:success, :payment_intent_id, :client_secret, :transfer_id,
                        :error, keyword_init: true) do
      def success?
        success
      end
    end

    CustomerResult = Struct.new(:success, :customer_id, :error, keyword_init: true) do
      def success?
        success
      end
    end

    EphemeralKeyResult = Struct.new(:success, :secret, :error, keyword_init: true) do
      def success?
        success
      end
    end

    def create_payment(checkout:)
      raise NotImplementedError
    end

    def create_customer(user:)
      raise NotImplementedError
    end

    def create_ephemeral_key(customer_id:)
      raise NotImplementedError
    end

    def refund(order:, amount_cents: nil)
      raise NotImplementedError
    end

    def transfer(order:)
      raise NotImplementedError
    end
  end
end
