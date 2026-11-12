# frozen_string_literal: true

module Carts
  # Adds a listing to a cart while enforcing the marketplace purchase rules.
  class AddItem
    Result = Struct.new(:success, :item, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(cart:, listing:, quantity: 1)
      @cart = cart
      @listing = listing
      @quantity = quantity.to_i
    end

    def call
      return failure("cart.errors.guest_disabled") if @cart.guest? && !Flipper.enabled?(:guest_checkout)
      return failure("cart.errors.invalid_quantity") unless @quantity.positive?
      return failure("cart.errors.own_listing") if own_listing?
      return failure("cart.errors.unavailable") unless @listing.publicly_visible?
      return failure("cart.errors.store_vacation") if @listing.store.vacation_mode?
      return failure("cart.errors.out_of_stock") unless @listing.quantity.to_i.positive?

      save_item
    end

    private

    def own_listing?
      @cart.user_id.present? && @listing.user_id == @cart.user_id
    end

    def save_item
      result = nil

      @cart.with_lock do
        item = @cart.items.find_or_initialize_by(listing: @listing)
        new_quantity = item.persisted? ? item.quantity + @quantity : @quantity

        if new_quantity > @listing.quantity.to_i
          result = failure("cart.errors.insufficient_stock")
          next
        end

        item.quantity = new_quantity
        if item.save
          result = Result.new(success: true, item: item, errors: [])
        else
          result = Result.new(success: false, item: item, errors: item.errors.full_messages)
        end
      end

      result
    end

    def failure(key)
      Result.new(success: false, item: nil, errors: [ I18n.t(key) ])
    end
  end
end
