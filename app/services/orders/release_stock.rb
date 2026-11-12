# frozen_string_literal: true

module Orders
  # Returns stock to the listing. Callers guard against double release with the
  # checkout/order state machine.
  class ReleaseStock
    def initialize(order:)
      @order = order
    end

    def call
      @order.items.includes(:listing).find_each do |item|
        item.listing.release_stock!(item.quantity)
      end
    end
  end
end
