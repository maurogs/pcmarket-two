# frozen_string_literal: true

class Payout < ApplicationRecord
  STATUSES = %w[pending paid failed].freeze

  belongs_to :order
  belongs_to :store

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :order_id, uniqueness: true

  def paid?
    status == "paid"
  end

  def failed?
    status == "failed"
  end
end
