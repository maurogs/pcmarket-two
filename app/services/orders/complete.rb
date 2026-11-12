# frozen_string_literal: true

module Orders
  # Completes a delivered order after the buyer-protection window and releases
  # the seller payout. A failed transfer never rolls back the completion.
  class Complete
    def initialize(order:)
      @order = order
    end

    def call
      return false unless @order.may_complete?

      completed = false

      @order.with_lock do
        next unless @order.may_complete?

        @order.complete!
        @order.events.create!(event: "completed", actor: nil)
        completed = true
      end

      Payouts::TransferToSeller.new(order: @order).call if completed
      completed
    end
  end
end
