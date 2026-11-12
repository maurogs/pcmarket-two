# frozen_string_literal: true

class CookieConsent < ApplicationRecord
  VERSION = "2026-11"
  COOKIE_NAME = "cookie_consent"
  MAX_AGE = 6.months
  CATEGORIES = %w[necessary preferences analytics marketing].freeze

  belongs_to :user

  validates :version, presence: true
  validates :consented_at, presence: true
  validate :categories_are_known

  def self.default_categories
    CATEGORIES.index_with { |category| category == "necessary" }
  end

  # Reads the first-party consent cookie. Unknown or malformed values are
  # treated as "no consent yet", never as opt-in.
  def self.categories_from_cookie(raw)
    defaults = default_categories
    return defaults if raw.blank?

    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw.to_h
    stored = parsed["categories"].presence || parsed[:categories].presence || parsed
    defaults.merge(
      stored.to_h.stringify_keys.slice(*CATEGORIES).transform_values do |value|
        ActiveModel::Type::Boolean.new.cast(value).present?
      end
    ).merge("necessary" => true)
  rescue JSON::ParserError, TypeError
    defaults
  end

  def self.payload(categories)
    {
      "categories" => default_categories.merge(
        categories.to_h.stringify_keys.slice(*CATEGORIES).transform_values do |value|
          ActiveModel::Type::Boolean.new.cast(value).present?
        end
      ).merge("necessary" => true),
      "version" => VERSION,
      "timestamp" => Time.current.iso8601
    }
  end

  def self.record!(user:, categories:, request: nil, version: VERSION)
    create!(
      user: user,
      categories: default_categories.merge(categories.to_h.stringify_keys.slice(*CATEGORIES)),
      version: version,
      consented_at: Time.current,
      ip: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end

  private

  def categories_are_known
    unknown = categories.to_h.keys - CATEGORIES
    return if unknown.empty?

    errors.add(:categories, :invalid)
  end
end
