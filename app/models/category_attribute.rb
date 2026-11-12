# frozen_string_literal: true

class CategoryAttribute < ApplicationRecord
  belongs_to :category
  belongs_to :attribute_definition

  validates :attribute_definition_id, uniqueness: { scope: :category_id }

  scope :ordered, -> { order(:position, :id) }

  after_commit :refresh_category_cache, on: %i[create update destroy]

  private

  # The navigation and descendant caches key off Category#updated_at.
  def refresh_category_cache
    Category.where(id: category_id).update_all(updated_at: Time.current)
  end
end
