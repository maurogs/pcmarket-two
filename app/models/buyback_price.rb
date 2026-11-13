# frozen_string_literal: true

class BuybackPrice < ApplicationRecord
  CONDITION_KEYS = %w[like_new good fair for_parts].freeze

  has_many :buyback_quotes, dependent: :restrict_with_error

  enum :component_type, { gpu: 0, cpu: 1 }, scopes: false

  validates :component_model, presence: true, length: { maximum: 120 }
  validates :base_offer_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :component_type, presence: true
  validate :condition_multipliers_are_valid

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:component_type, :component_model, :id) }
  scope :for_component, ->(type) { where(component_type: type) }

  before_validation :normalise_component_model

  def condition_multiplier(condition)
    condition_multipliers.to_h[condition.to_s].to_f
  end

  def conditions
    CONDITION_KEYS
  end

  private

  def normalise_component_model
    self.component_model = component_model.to_s.squish
  end

  def condition_multipliers_are_valid
    values = condition_multipliers.to_h
    missing = CONDITION_KEYS - values.keys
    errors.add(:condition_multipliers, :invalid) if missing.any?

    values.each_value do |value|
      next if value.to_s.match?(/\A\d+(\.\d+)?\z/) && value.to_f.positive?

      errors.add(:condition_multipliers, :invalid)
      break
    end
  end
end
