# frozen_string_literal: true

class AttributeOption < ApplicationRecord
  extend Mobility

  translates :label

  belongs_to :attribute_definition, inverse_of: :attribute_options

  validates :value, presence: true,
                    uniqueness: { scope: :attribute_definition_id }
  validates :label, presence: true

  scope :active, -> { where(active: true) }
  scope :popular, -> { where(popular: true) }
  scope :ordered, -> { order(:position, :id) }
end
