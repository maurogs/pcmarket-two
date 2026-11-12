# frozen_string_literal: true

module Api
  module V1
    class OrderItemSerializer < BaseSerializer
      attributes :id, :listing_id, :quantity, :unit_price_cents,
                 :shipping_cents, :title, :seller_name, :photo_url, :specs

      attribute :line_total_cents, &:line_total_cents
    end
  end
end
