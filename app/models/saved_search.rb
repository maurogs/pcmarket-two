# frozen_string_literal: true

class SavedSearch < ApplicationRecord
  FREQUENCIES = %w[instant daily weekly].freeze
  MAX_PER_USER = 50

  belongs_to :user
  belongs_to :category, optional: true

  validates :name, presence: true, length: { in: 2..80 }
  validates :frequency, inclusion: { in: FREQUENCIES }
  validate :query_params_is_a_hash
  validate :within_user_limit, on: :create

  before_validation :normalize_query_params

  def to_search_params
    params = (query_params || {}).deep_stringify_keys
    params["category"] = category.slug if category.present?
    params
  end

  # All criteria are ANDed. The category is a subtree, so a search saved on a
  # parent category also matches listings in any descendant.
  def matches?(listing)
    return false if listing.blank?
    return false unless category_matches?(listing)
    return false unless price_matches?(listing)
    return false unless condition_matches?(listing)
    return false unless specs_match?(listing)
    return false unless tags_match?(listing)
    return false unless region_matches?(listing)
    return false unless free_shipping_matches?(listing)

    query_matches?(listing)
  end

  def instant?
    frequency == "instant"
  end

  def digest?
    %w[daily weekly].include?(frequency)
  end

  def digest_due?
    case frequency
    when "daily"
      last_notified_at.nil? || last_notified_at <= 1.day.ago
    when "weekly"
      last_notified_at.nil? || last_notified_at <= 1.week.ago
    else
      false
    end
  end

  def email_due?
    instant? || digest_due?
  end

  private

  def normalize_query_params
    self.query_params = ListingSearch.normalize_params(query_params, category: category)
  end

  def query_params_is_a_hash
    return if query_params.is_a?(Hash)

    errors.add(:query_params, I18n.t("saved_searches.errors.invalid_query_params"))
  end

  def within_user_limit
    return if user.blank?
    return if user.saved_searches.where.not(id: id).count < MAX_PER_USER

    errors.add(:base, I18n.t("saved_searches.errors.limit_reached", max: MAX_PER_USER))
  end

  def category_matches?(listing)
    return true if category.blank?

    category_descendant_ids.include?(listing.category_id)
  end

  def category_descendant_ids
    @category_descendant_ids ||= category.descendant_ids
  end

  def price_matches?(listing)
    min = numeric_param(query_params["min_price"])
    max = numeric_param(query_params["max_price"])
    return true if min.nil? && max.nil?
    return false if listing.price_cents.nil?

    price = listing.price_cents.to_i
    return false if min && price < (min * 100).round
    return false if max && price > (max * 100).round

    true
  end

  def condition_matches?(listing)
    conditions = Array(query_params["condition"]).map(&:to_s).reject(&:empty?)
    return true if conditions.empty?

    conditions.include?(listing.condition.to_s)
  end

  def specs_match?(listing)
    specs = query_params["specs"]
    return true unless specs.is_a?(Hash)

    listing_specs = listing.specs || {}
    specs.all? do |key, raw_values|
      values = Array(raw_values).map(&:to_s).reject(&:empty?)
      next true if values.empty?

      current = Array(listing_specs[key.to_s]).map(&:to_s)
      (values & current).any?
    end
  end

  def tags_match?(listing)
    slugs = Array(query_params["tags"]).map(&:to_s).reject(&:empty?)
    return true if slugs.empty?

    (slugs & listing.tags.map(&:slug)).any?
  end

  def region_matches?(listing)
    region = integer_param(query_params["region"])
    return true if region.nil?

    listing.region_id == region
  end

  def free_shipping_matches?(listing)
    return true unless truthy?(query_params["free_shipping"])

    listing.free_shipping?
  end

  def query_matches?(listing)
    query = query_params["q"].to_s.strip
    return true if query.blank?

    Listing.search_text(query).where(id: listing.id).exists?
  end

  def numeric_param(value)
    return nil if value.nil? || value.to_s.strip.empty?

    number = BigDecimal(value.to_s)
    number.finite? && number >= 0 ? number : nil
  rescue ArgumentError, TypeError
    nil
  end

  def integer_param(value)
    return nil if value.nil? || value.to_s.strip.empty?

    Integer(value, exception: false)
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value).present?
  end
end
