# frozen_string_literal: true

module Orders
  # Buyer or seller cancels an unshipped order, refunds it when already paid and
  # restocks the listing.
  class Cancel
    def initialize(order:, actor:, reason: nil, gateway: Payments.gateway)
      @order = order
      @actor = actor
      @reason = reason
      @gateway = gateway
    end

    def call
      return false unless @order.may_cancel?
      return false unless authorised?

      cancelled = false

      @order.with_lock do
        next unless @order.may_cancel?

        refund = refund_if_paid
        next if refund == false

        Orders::ReleaseStock.new(order: @order).call
        @order.cancel!
        @order.events.create!(event: "cancelled", actor: @actor, data: { reason: @reason.presence })
        cancelled = true
      end

      notify_counterpart if cancelled
      cancelled
    end

    private

    def authorised?
      return false if @actor.blank?

      @actor.id == @order.buyer_id || @actor.id == @order.store.user_id
    end

    def refund_if_paid
      return true unless @order.paid?

      @gateway.refund(order: @order).success?
    end

    def notify_counterpart
      recipient = if @actor.id == @order.buyer_id
        @order.store.user
      else
        @order.buyer
      end
      recipient ||= @order.checkout.recipient_email

      OrderMailer.order_cancelled(@order, recipient: recipient).deliver_later if recipient.present?
    end
  end
end
