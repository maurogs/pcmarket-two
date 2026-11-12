# frozen_string_literal: true

module Orders
  # Completes a delivered order after the buyer-protection window.
  class Complete
    def initialize(order:)
      @order = order
    end

    def call
      return false unless @order.may_complete?

      @order.with_lock do
        next unless @order.may_complete?

        @order.complete!
        @order.events.create!(event: "completed", actor: nil)
      end

      true
    end
  end
end
