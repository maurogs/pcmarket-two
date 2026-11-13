# frozen_string_literal: true

module Api
  module V1
    class OrderSerializer < BaseSerializer
      attributes :id, :number, :status, :fulfilment, :subtotal_cents,
                 :shipping_cents, :commission_cents, :total_cents, :currency,
                 :tracking_carrier, :tracking_number, :paid_at, :shipped_at,
                 :delivered_at, :completed_at, :cancelled_at,
                 :buyer_protection_ends_at, :created_at, :updated_at

      attribute :store do |order|
        StoreSummarySerializer.new(order.store).serializable_hash
      end

      many :items, resource: OrderItemSerializer

      attribute :review_id do |order|
        order.review&.id
      end

      attribute :reviewable do |order|
        order.reviewable?
      end
    end
  end
end
