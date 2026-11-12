# frozen_string_literal: true

module Api
  module V1
    class CheckoutSerializer < BaseSerializer
      attributes :id, :status, :subtotal_cents, :shipping_cents, :total_cents,
                 :payment_intent_id, :created_at, :updated_at, :expires_at

      many :orders, resource: OrderSerializer

      attribute :currency do |checkout|
        checkout.orders.first&.currency.presence || "EUR"
      end
    end
  end
end
