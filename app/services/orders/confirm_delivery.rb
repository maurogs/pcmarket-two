# frozen_string_literal: true

module Orders
  # Buyer confirms receipt, opens the buyer-protection window and schedules the
  # automatic completion.
  class ConfirmDelivery
    def initialize(order:, actor:)
      @order = order
      @actor = actor
    end

    def call
      return false unless @order.may_confirm_delivery?
      return false unless @actor.present? && @order.buyer_id == @actor.id

      ends_at = nil

      @order.with_lock do
        next unless @order.may_confirm_delivery?

        @order.confirm_delivery!
        @order.events.create!(event: "delivered", actor: @actor)
        ends_at = @order.buyer_protection_ends_at
      end

      if ends_at.present?
        OrderMailer.delivery_confirmed(@order).deliver_later
        Notifications.record(
          recipient: @order.store.user,
          kind: "order_delivered",
          notifiable: @order,
          params: { number: @order.number }
        )
        AutoCompleteOrderJob.set(wait_until: ends_at).perform_later(@order)
        Reviews::ReminderJob.set(wait_until: @order.delivered_at + 3.days)
                            .perform_later(@order.id)
      end

      ends_at.present?
    end
  end
end
