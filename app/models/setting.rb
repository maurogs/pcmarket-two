# frozen_string_literal: true

class Setting < ApplicationRecord
  MISSING = :__missing__

  VALUE_TYPES = %w[boolean integer decimal string text].freeze

  validates :key, presence: true, uniqueness: true
  validates :value_type, inclusion: { in: VALUE_TYPES }

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

  def invalidate_cache
    Rails.cache.delete(self.class.cache_key(key))
  end

  private_class_method :infer_value_type
end
