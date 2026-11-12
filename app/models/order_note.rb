# frozen_string_literal: true

# Staff-only note attached to an order (never shown to buyers or sellers).
class OrderNote < ApplicationRecord
  belongs_to :order
  belongs_to :author, class_name: "User"

  validates :body, presence: true, length: { maximum: 4000 }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
end
