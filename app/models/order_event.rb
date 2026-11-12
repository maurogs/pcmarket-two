# frozen_string_literal: true

class OrderEvent < ApplicationRecord
  belongs_to :order
  belongs_to :actor, class_name: "User", optional: true

  validates :event, presence: true

  scope :chronological, -> { order(created_at: :asc, id: :asc) }
end
