# frozen_string_literal: true

module Payments
  class Gateway
    Result = Struct.new(:success, :payment_intent_id, :client_secret, :transfer_id,
                        :error, keyword_init: true) do
      def success?
        success
      end
    end

    def create_payment(checkout:)
      raise NotImplementedError
    end

    def refund(order:)
      raise NotImplementedError
    end

    def transfer(order:)
      raise NotImplementedError
    end
  end
end
