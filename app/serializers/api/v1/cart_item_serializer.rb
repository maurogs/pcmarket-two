# frozen_string_literal: true

module Api
  module V1
    class CartItemSerializer < BaseSerializer
      attributes :id, :quantity, :unit_price_cents, :offer_id

      attribute :line_total_cents, &:line_total_cents
      attribute :effective_unit_price_cents, &:effective_unit_price_cents
      attribute :purchasable, &:purchasable?
      attribute :listing do |item|
        ListingCardSerializer.new(item.listing).serializable_hash
      end
    end
  end
end
