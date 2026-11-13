# frozen_string_literal: true

module Carts
  # Changes a cart line quantity. Zero or a negative quantity removes the line.
  class UpdateItem
    Result = Struct.new(:success, :item, :removed, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(item:, quantity:)
      @item = item
      @quantity = quantity.to_i
    end

    def call
      if @quantity <= 0
        @item.destroy!
        return Result.new(success: true, item: @item, removed: true, errors: [])
      end

      if @item.update(quantity: @quantity)
        Result.new(success: true, item: @item, removed: false, errors: [])
      else
        Result.new(success: false, item: @item, removed: false,
                   errors: @item.errors.full_messages)
      end
    end
  end
end
