# frozen_string_literal: true

module Payouts
  # Transfers a completed order's net amount to the seller's connected account.
  # Failures are recorded on the payout but never roll back the completion.
  class TransferToSeller
    def initialize(order:, gateway: Payments.gateway)
      @order = order
      @gateway = gateway
    end

    def call
      return false unless @order.completed?

      payout = Payout.find_or_initialize_by(order: @order)
      return true if payout.paid?

      payout.assign_attributes(store: @order.store, amount_cents: net_amount)
      payout.save!

      result = @gateway.transfer(order: @order)
      if result.success?
        payout.update!(status: "paid", stripe_transfer_id: result.transfer_id, error: nil)
        true
      else
        payout.update!(status: "failed", error: result.error)
        false
      end
    end

    private

    def net_amount
      [ @order.total_cents.to_i - @order.commission_cents.to_i, 0 ].max
    end
  end
end
