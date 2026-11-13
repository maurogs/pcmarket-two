# frozen_string_literal: true

module Api
  module V1
    class CartSerializer < BaseSerializer
      attributes :id, :item_count, :subtotal_cents, :shipping_cents,
                 :total_cents, :created_at, :updated_at

      many :items, resource: CartItemSerializer

      attribute :groups do |cart|
        cart.groups.map do |group|
          {
            store: StoreSummarySerializer.new(group.store).serializable_hash,
            shipping_cents: group.shipping_cents,
            subtotal_cents: group.subtotal_cents,
            total_cents: group.total_cents,
            items: group.items.map { |item| CartItemSerializer.new(item).serializable_hash }
          }
        end
      end
    end
  end
end
