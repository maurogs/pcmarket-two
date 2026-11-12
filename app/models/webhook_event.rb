# frozen_string_literal: true

class WebhookEvent < ApplicationRecord
  self.inheritance_column = nil

  validates :provider, :event_id, :type, presence: true
  validates :event_id, uniqueness: { scope: :provider }

  scope :processed, -> { where.not(processed_at: nil) }
  scope :pending, -> { where(processed_at: nil) }

  def processed?
    processed_at.present?
  end
end
