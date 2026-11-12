# frozen_string_literal: true

class AttributeOption < ApplicationRecord
  extend Mobility

  translates :label

  belongs_to :attribute_definition, inverse_of: :attribute_options

  validates :value, presence: true,
                    uniqueness: { scope: :attribute_definition_id }
  validates :label, presence: true
  validate :value_is_locked_once_used

  scope :active, -> { where(active: true) }
  scope :popular, -> { where(popular: true) }
  scope :ordered, -> { order(:position, :id) }

  # True when at least one listing stores this option value under the
  # definition key, either as a scalar or inside an array.
  def used?
    return false if attribute_definition.blank? || value.blank?

    listing_using_value_exists?(value)
  end

  def usage_count
    Admin::AttributeUsage.for(attribute_definition)[value].to_i
  end

  private

  def listing_using_value_exists?(candidate)
    Listing.where(
      "specs @> ?::jsonb OR specs @> ?::jsonb",
      { attribute_definition.key => candidate }.to_json,
      { attribute_definition.key => [ candidate ] }.to_json
    ).exists?
  end

  def value_is_locked_once_used
    return unless persisted? && will_save_change_to_value?

    old_value = value_in_database
    return if old_value.blank?
    return unless listing_using_value_exists?(old_value)

    errors.add(:value, I18n.t("attribute_definitions.errors.value_locked"))
  end
end
