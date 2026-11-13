# frozen_string_literal: true

class Setting < ApplicationRecord
  MISSING = :__missing__

  VALUE_TYPES = %w[boolean integer decimal string text].freeze

  validates :key, presence: true, uniqueness: true
  validates :value_type, inclusion: { in: VALUE_TYPES }
  validate :value_matches_declared_type
  validate :value_matches_key_rules

  after_commit :invalidate_cache, on: %i[create update destroy]

  def self.get(key, default = nil)
    value = Rails.cache.fetch(cache_key(key)) do
      record = find_by(key: key)
      record ? record.typed_value : MISSING
    end

    value == MISSING ? default : value
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value
    record.value_type = infer_value_type(value)
    record.save!
    record
  end

  def self.cache_key(key)
    "settings/#{key}"
  end

  def typed_value
    case value_type
    when "boolean" then ActiveModel::Type::Boolean.new.cast(value)
    when "integer" then value.nil? ? nil : value.to_i
    when "decimal" then value.nil? ? nil : value.to_d
    else value
    end
  end

  def self.infer_value_type(value)
    case value
    when TrueClass, FalseClass then "boolean"
    when Integer then "integer"
    when Float, BigDecimal then "decimal"
    else "string"
    end
  end

  private

  def value_matches_declared_type
    return if value.nil?

    valid = case value_type
    when "boolean"
      [ true, false ].include?(value)
    when "integer"
      value.is_a?(Integer) || value.to_s.match?(/\A-?\d+\z/)
    when "decimal"
      value.is_a?(Numeric) || !BigDecimal(value.to_s, exception: false).nil?
    else
      true
    end

    errors.add(:value, I18n.t("settings.errors.invalid_type")) unless valid
  end

  def value_matches_key_rules
    value = typed_value
    decimal = value.is_a?(Numeric) ? value.to_d : value.to_s.to_d
    integer = value.is_a?(Numeric) ? value.to_i : value.to_s.to_i

    case key
    when "commission_percent"
      errors.add(:value, I18n.t("settings.errors.commission_percent")) unless decimal.between?(0, 50)
    when "max_images_per_listing"
      errors.add(:value, I18n.t("settings.errors.max_images_per_listing")) unless integer.between?(1, 30)
    when "buyer_protection_days"
      errors.add(:value, I18n.t("settings.errors.buyer_protection_days")) unless integer.between?(0, 90)
    when "min_listing_price", "max_listing_price", "featured_listing_price"
      errors.add(:value, I18n.t("settings.errors.negative")) if decimal.negative?
    end
  end

  def invalidate_cache
    Rails.cache.delete(self.class.cache_key(key))
  end

  private_class_method :infer_value_type
end
