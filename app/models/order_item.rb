# frozen_string_literal: true

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :listing

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, :shipping_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :title, :seller_name, presence: true

  def line_total_cents
    unit_price_cents * quantity
  end
end
