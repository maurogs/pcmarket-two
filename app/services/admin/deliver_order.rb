# frozen_string_literal: true

module Admin
  # Staff confirms delivery on behalf of the buyer, opening the protection
  # window in the same way as the buyer-facing flow.
  class DeliverOrder
    def initialize(order:, actor:)
      @order = order
      @actor = actor
    end

    def call
      delivered = false

      @order.with_lock do
        next unless @order.may_confirm_delivery?

        @order.confirm_delivery!
        @order.events.create!(event: "delivered", actor: @actor, data: { by: "admin" })
        delivered = true
      end

      if delivered && @order.buyer_protection_ends_at.present?
        AutoCompleteOrderJob.set(wait_until: @order.buyer_protection_ends_at).perform_later(@order)
      end

      delivered
    end
  end
end
