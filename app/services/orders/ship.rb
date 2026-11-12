# frozen_string_literal: true

module Orders
  # Seller marks a paid order as shipped. A carrier and tracking number are
  # required for shipped orders; collections do not need them.
  class Ship
    def initialize(order:, actor:, carrier: nil, tracking_number: nil)
      @order = order
      @actor = actor
      @carrier = carrier
      @tracking_number = tracking_number
    end

    def call
      return false unless @order.paid?
      return false if @actor.blank? || @order.store.user_id != @actor.id
      return false unless valid_carrier?

      shipped = false

      @order.with_lock do
        next unless @order.paid?

        @order.tracking_carrier = @carrier.presence
        @order.tracking_number = @tracking_number.presence
        next unless @order.shipping_details_ready?

        @order.ship!
        @order.events.create!(event: "shipped", actor: @actor, data: tracking_data)
        shipped = true
      end

      OrderMailer.order_shipped(@order).deliver_later if shipped
      shipped
    end

    private

    def valid_carrier?
      @carrier.blank? || Order::CARRIERS.include?(@carrier.to_s)
    end

    def tracking_data
      { carrier: @order.tracking_carrier, tracking_number: @order.tracking_number }
    end
  end
end
