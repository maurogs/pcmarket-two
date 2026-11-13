# frozen_string_literal: true

module Admin
  # Closes a disputed order: either refunds the buyer through the gateway or
  # releases the funds to the seller (and triggers the payout).
  class ResolveDispute
    DECISIONS = %w[refund release].freeze

    def initialize(order:, actor:, decision:, note: nil, gateway: Payments.gateway)
      @order = order
      @actor = actor
      @decision = decision.to_s
      @note = note.to_s.strip
      @gateway = gateway
    end

    def call
      return false unless @order.disputed?
      return false unless DECISIONS.include?(@decision)

      resolved = false

      @order.with_lock do
        next unless @order.disputed?

        case @decision
        when "refund"
          next unless @gateway.refund(order: @order).success?

          @order.refund!
          @order.events.create!(event: "refunded", actor: @actor, data: { note: @note.presence, by: "admin" })
        when "release"
          @order.resolve!
          @order.events.create!(event: "completed", actor: @actor, data: { note: @note.presence, by: "admin" })
        end

        resolved = true
      end

      Payouts::TransferToSeller.new(order: @order).call if resolved && @decision == "release"
      resolved
    end
  end
end
