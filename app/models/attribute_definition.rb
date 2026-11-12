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
  validate :input_type_is_locked_once_used
  validate :key_is_immutable, on: :update

  scope :active, -> { where(active: true) }
  scope :filterable, -> { where(filterable: true) }
  scope :ordered, -> { order(:position, :id) }

  after_commit { Category.expire_attribute_definitions_cache }

  def select_type?
    single_select? || multi_select?
  end

  # A definition is in use as soon as any listing stores its key, even if the
  # stored value is an empty array.
  def used?
    return false if key.blank?

    Listing.where("specs ? :key", key: key).exists?
  end

  def usage_count
    return 0 if key.blank?

    Listing.where("specs ? :key", key: key).count
  end

  private

  def input_type_is_locked_once_used
    return unless persisted? && will_save_change_to_input_type?
    return unless used?

    errors.add(:input_type, I18n.t("attribute_definitions.errors.input_type_locked"))
  end

  def key_is_immutable
    return if key == key_in_database

    errors.add(:key, I18n.t("attribute_definitions.errors.key_immutable"))
  end
end
