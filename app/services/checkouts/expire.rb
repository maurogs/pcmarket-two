# frozen_string_literal: true

module Checkouts
  # Releases reservations when the 15-minute payment window lapses.
  class Expire
    def initialize(checkout:)
      @checkout = checkout
    end

    def call
      return false unless @checkout.pending?

      expired = false

      @checkout.with_lock do
        next unless @checkout.pending?

        cancel_orders
        @checkout.update!(status: "expired")
        expired = true
      end

      expired
    end

    private

    def cancel_orders
      @checkout.orders.includes(items: :listing).find_each do |order|
        next unless order.may_cancel?

        Orders::ReleaseStock.new(order: order).call
        order.cancel!
        order.events.create!(event: "expired", actor: nil)
      end
    end
  end
end
