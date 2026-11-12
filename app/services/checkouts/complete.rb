# frozen_string_literal: true

module Checkouts
  # Marks a successful payment as paid, sells the reserved stock and enqueues
  # the buyer/seller emails. Safe to call twice.
  class Complete
    def initialize(checkout:, cart: nil)
      @checkout = checkout
      @cart = cart
    end

    def call
      return false unless @checkout.pending?

      completed = false

      @checkout.with_lock do
        next unless @checkout.pending?

        @checkout.orders.includes(items: :listing).find_each do |order|
          next unless order.may_pay?

          order.pay!
          order.items.each { |item| item.listing.mark_sold_after_sale! }
          order.events.create!(event: "paid", actor: @checkout.buyer)
        end

        @checkout.update!(status: "paid")
        cleanup_cart
        completed = true
      end

      enqueue_emails if completed
      completed
    end

    private

    def cleanup_cart
      cart = @cart || @checkout.buyer&.cart
      cart&.items&.where(listing_id: purchased_listing_ids)&.destroy_all
    end

    def purchased_listing_ids
      @checkout.orders.flat_map { |order| order.items.map(&:listing_id) }.uniq
    end

    def enqueue_emails
      @checkout.orders.includes(:items, store: :user).find_each do |order|
        OrderMailer.buyer_confirmation(order).deliver_later
        OrderMailer.seller_new_sale(order).deliver_later
        next unless order.paid?

        Notifications.record(
          recipient: order.store.user,
          kind: "new_sale",
          notifiable: order,
          params: {
            number: order.number,
            title: order.items.first&.title,
            total_cents: order.total_cents,
            currency: order.currency
          }
        )
      end
    end
  end
end
