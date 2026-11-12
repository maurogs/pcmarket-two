# frozen_string_literal: true

class AttributeDefinition < ApplicationRecord
  extend Mobility

  translates :name

  has_many :attribute_options, -> { order(:position, :id) },
           dependent: :destroy, inverse_of: :attribute_definition
  has_many :category_attributes, dependent: :destroy, inverse_of: :attribute_definition
  has_many :categories, through: :category_attributes

  enum :input_type, {
    single_select: 0,
    multi_select: 1,
    number: 2,
    boolean: 3,
    text: 4
  }, scopes: false

  validates :key, presence: true, uniqueness: true,
                  format: { with: /\A[a-z0-9_]+\z/ }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :filterable, -> { where(filterable: true) }
  scope :ordered, -> { order(:position, :id) }

  def select_type?
    single_select? || multi_select?
  end
end
