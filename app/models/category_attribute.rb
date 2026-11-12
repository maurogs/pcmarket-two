# frozen_string_literal: true

class CategoryAttribute < ApplicationRecord
  belongs_to :category
  belongs_to :attribute_definition

  validates :attribute_definition_id, uniqueness: { scope: :category_id }

  scope :ordered, -> { order(:position, :id) }
end
