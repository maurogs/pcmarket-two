# frozen_string_literal: true

module Admin
  # Staff cancellation on behalf of a buyer or seller. Refunds a paid order and
  # releases reserved stock.
  class CancelOrder
    def initialize(order:, actor:, reason: nil, gateway: Payments.gateway)
      @order = order
      @actor = actor
      @reason = reason.to_s.strip
      @gateway = gateway
    end

    def call
      return false unless @order.may_cancel?

      cancelled = false

      @order.with_lock do
        next unless @order.may_cancel?
        next if @order.paid? && !@gateway.refund(order: @order).success?

        Orders::ReleaseStock.new(order: @order).call
        @order.cancel!
        @order.events.create!(
          event: "cancelled",
          actor: @actor,
          data: { reason: @reason.presence, by: "admin" }
        )
        cancelled = true
      end

      cancelled
    end
  end
end
