# frozen_string_literal: true

module Admin
  # Issues a gateway refund for part of an order total and records it on the
  # order timeline. The order status is intentionally left untouched so the
  # original fulfilment history stays intact.
  class PartialRefund
    REFUNDABLE_STATUSES = %w[paid shipped delivered completed disputed].freeze

    def initialize(order:, actor:, amount_cents:, gateway: Payments.gateway)
      @order = order
      @actor = actor
      @amount_cents = amount_cents.to_i
      @gateway = gateway
    end

    def call
      return false unless REFUNDABLE_STATUSES.include?(@order.status)
      return false unless @amount_cents.positive? && @amount_cents <= @order.total_cents

      result = @gateway.refund(order: @order, amount_cents: @amount_cents)
      return false unless result.success?

      @order.events.create!(
        event: "partial_refund",
        actor: @actor,
        data: { amount_cents: @amount_cents, currency: @order.currency }
      )
      true
    end
  end
end
