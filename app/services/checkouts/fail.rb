# frozen_string_literal: true

module Checkouts
  # Releases reservations after a declined payment. Safe to call twice.
  class Fail
    def initialize(checkout:)
      @checkout = checkout
    end

    def call
      return false unless @checkout.pending?

      released = false

      @checkout.with_lock do
        next unless @checkout.pending?

        cancel_orders
        @checkout.update!(status: "failed")
        released = true
      end

      released
    end

    private

    def cancel_orders
      @checkout.orders.includes(items: :listing).find_each do |order|
        next unless order.may_cancel?

        Orders::ReleaseStock.new(order: order).call
        order.cancel!
        order.events.create!(event: "payment_failed", actor: @checkout.buyer)
      end
    end
  end
end
