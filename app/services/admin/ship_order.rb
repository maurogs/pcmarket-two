# frozen_string_literal: true

module Admin
  # Marks a paid order as shipped on behalf of the seller. Mirrors
  # Orders::Ship but without the seller ownership check.
  class ShipOrder
    def initialize(order:, actor:, carrier:, tracking_number:)
      @order = order
      @actor = actor
      @carrier = carrier.to_s.strip
      @tracking_number = tracking_number.to_s.strip
    end

    def call
      return false unless @order.paid?
      return false if @carrier.present? && !Order::CARRIERS.include?(@carrier)

      shipped = false

      @order.with_lock do
        next unless @order.paid?

        @order.tracking_carrier = @carrier.presence
        @order.tracking_number = @tracking_number.presence
        next unless @order.shipping_details_ready?

        @order.ship!
        @order.events.create!(
          event: "shipped",
          actor: @actor,
          data: { carrier: @order.tracking_carrier, tracking_number: @order.tracking_number, by: "admin" }
        )
        shipped = true
      end

      if shipped
        OrderMailer.order_shipped(@order).deliver_later
        Notifications.record(
          recipient: @order.buyer,
          kind: "order_shipped",
          notifiable: @order,
          params: { number: @order.number }
        )
      end

      shipped
    end
  end
end
