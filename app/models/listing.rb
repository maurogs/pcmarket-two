# frozen_string_literal: true

class Listing < ApplicationRecord
  include AASM
  include PgSearch::Model
  extend FriendlyId

  STATUSES = %w[draft pending_review published rejected reserved sold archived].freeze
  # Edits that require a fresh moderation pass; price, quantity and shipping
  # changes deliberately stay live.
  MATERIAL_ATTRIBUTES = %w[title description category_id specs].freeze

  belongs_to :store
  belongs_to :category
  belongs_to :region, optional: true
  belongs_to :seller, class_name: "User", foreign_key: :user_id, inverse_of: :listings

  has_many :photos, -> { order(:position, :id) },
           class_name: "ListingPhoto", dependent: :destroy, inverse_of: :listing
  has_many :listing_tags, dependent: :destroy
  has_many :tags, through: :listing_tags
  has_many :moderations, class_name: "ListingModeration", dependent: :destroy

  friendly_id :slug_source, use: :slugged

  enum :condition, {
    new_sealed: 0,
    new_open_box: 1,
    used_like_new: 2,
    used_good: 3,
    used_fair: 4,
    for_parts: 5
  }, scopes: false

  enum :shipping_mode, {
    shipping: 0,
    local_pickup: 1,
    shipping_and_pickup: 2
  }, scopes: false

  validates :title, presence: true, length: { in: 5..140 }
  validates :description, presence: true, length: { in: 20..10_000 }
  validates :slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :price_cents, presence: true,
                          numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :shipping_price_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :handling_days, numericality: { only_integer: true, in: 1..10 }
  validates :views_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :favorites_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rejection_reason, presence: true, if: :rejected?
  validate :price_within_settings
  validate :compare_at_price_above_price
  validate :country_is_launched
  validate :region_belongs_to_country
  validate :required_specs_present, unless: :draft?
  validate :spec_values_are_active_options

  # Material edits of a live listing go back through moderation in the very
  # same save, so counter callbacks observe a single status change.
  before_save :reopen_for_review_on_material_edit,
              if: :material_edit_on_published_listing?

  before_destroy :remember_counter_snapshot
  after_commit :sync_listing_counters, on: %i[create update destroy]

  pg_search_scope :search_text,
                  against: :title,
                  using: {
                    tsearch: {
                      tsvector_column: :searchable,
                      prefix: true,
                      dictionary: "simple"
                    },
                    trigram: { threshold: 0.2 }
                  },
                  ignoring: :accents,
                  ranked_by: ":tsearch + (0.25 * :trigram)"

  aasm column: :status, whiny_transitions: false do
    state :draft, initial: true
    state :pending_review
    state :published
    state :rejected
    state :reserved
    state :sold
    state :archived

    event :submit do
      before :mark_submitted
      transitions from: %i[draft rejected], to: :pending_review,
                  guard: :approval_required?
      transitions from: %i[draft rejected], to: :published,
                  guard: :approval_not_required?
    end

    event :approve do
      before :mark_published
      transitions from: :pending_review, to: :published
    end

    event :reject do
      before :assign_rejection_reason
      transitions from: :pending_review, to: :rejected,
                  guard: :rejection_reason_provided?
    end

    event :reserve do
      transitions from: :published, to: :reserved
    end

    event :release do
      transitions from: :reserved, to: :published
    end

    event :mark_sold do
      before :mark_sold_at
      transitions from: %i[published reserved], to: :sold
    end

    event :archive do
      before :mark_archived_at
      transitions from: %i[draft pending_review published rejected reserved],
                  to: :archived
    end

    event :republish do
      before :mark_republished
      transitions from: :archived, to: :pending_review,
                  guard: :approval_required?
      transitions from: :archived, to: :published,
                  guard: :approval_not_required?
    end
  end

  scope :published, -> { where(status: "published") }
  scope :visible, lambda {
    published
      .joins(:store)
      .merge(Store.active)
      .joins(:seller)
      .where(users: { banned_at: nil, deleted_at: nil })
  }
  scope :in_category, lambda { |category|
    ids = category.respond_to?(:descendant_ids) ? category.descendant_ids : Array(category)
    where(category_id: ids)
  }
  scope :by_condition, ->(condition) { where(condition: condition) }
  scope :price_between, ->(range) { where(price_cents: range) }
  scope :in_region, lambda { |region|
    where(region_id: region.respond_to?(:id) ? region.id : region)
  }
  scope :featured, -> { where("featured_until > ?", Time.current) }

  def self.approval_required?
    Setting.get(:listings_require_approval, true)
  end

  # AND across keys, OR across the values of a single key. Supports both scalar
  # and array-valued specs with plain bind parameters.
  def self.with_specs(filter)
    return all if filter.blank?

    filter.to_h.reduce(all) do |relation, (raw_key, raw_values)|
      key = raw_key.to_s
      values = Array(raw_values).map(&:to_s).reject(&:empty?)
      next relation if values.empty?

      clauses = Array.new(values.size, "(specs @> ?::jsonb OR specs @> ?::jsonb)")
      binds = values.flat_map do |value|
        [ { key => value }.to_json, { key => [ value ] }.to_json ]
      end
      relation.where("(#{clauses.join(' OR ')})", *binds)
    end
  end

  def self.sorted_by(key)
    case key.to_s
    when "price_asc"  then order(price_cents: :asc, id: :asc)
    when "price_desc" then order(price_cents: :desc, id: :desc)
    when "popular"    then order(favorites_count: :desc, views_count: :desc, id: :desc)
    when "relevance"
      # pg_search already orders by its rank; expose the rank column when the
      # relation comes from search_text, otherwise fall back to newest.
      all.respond_to?(:with_pg_search_rank) ? all.with_pg_search_rank : order(published_at: :desc, id: :desc)
    else order(published_at: :desc, id: :desc)
    end
  end

  def approval_required?
    self.class.approval_required?
  end

  def approval_not_required?
    !approval_required?
  end

  def price
    return if price_cents.nil?

    BigDecimal(price_cents) / 100
  end

  def discount_percent
    return if compare_at_price_cents.blank? || price_cents.blank?
    return if compare_at_price_cents <= price_cents

    ((compare_at_price_cents - price_cents) * 100.0 / compare_at_price_cents).round
  end

  def primary_photo
    photos.first
  end

  # Called when a photo is added or removed: photos are a material edit.
  def reopen_for_review_after_photo_change!
    return unless persisted? && status == "published" && approval_required?

    update!(status: "pending_review")
  end

  def slug_source
    "#{title}-#{SecureRandom.hex(3)}"
  end

  private

  def specs_hash
    (specs || {}).with_indifferent_access
  end

  def spec_value_present?(key)
    value = specs_hash[key]
    value.is_a?(Array) ? value.any?(&:present?) : value.present?
  end

  def price_within_settings
    return if price_cents.blank? || !price_cents.is_a?(Numeric)

    min = Setting.get(:min_listing_price, 1).to_i * 100
    max = Setting.get(:max_listing_price, 50_000).to_i * 100
    return if price_cents.between?(min, max)

    errors.add(:price_cents,
               I18n.t("listings.errors.price_out_of_range",
                      min: min / 100, max: max / 100))
  end

  def compare_at_price_above_price
    return if compare_at_price_cents.blank? || price_cents.blank?
    return if compare_at_price_cents > price_cents

    errors.add(:compare_at_price_cents, I18n.t("listings.errors.compare_at_price"))
  end

  def country_is_launched
    return if country_code.blank?
    return if Country.launched_codes.include?(country_code)

    errors.add(:country_code, I18n.t("listings.errors.country_not_launched"))
  end

  def region_belongs_to_country
    return if region.blank? || country_code.blank?
    return if region.country_code == country_code

    errors.add(:region_id, I18n.t("listings.errors.region_country_mismatch"))
  end

  def required_specs_present
    return if category.blank?

    missing = category.effective_category_attributes
                      .select(&:required?)
                      .map(&:attribute_definition)
                      .reject { |definition| spec_value_present?(definition.key) }
                      .map { |definition| definition.name.presence || definition.key }
    return if missing.empty?

    errors.add(:specs,
               I18n.t("listings.errors.required_specs",
                      attributes: missing.to_sentence))
  end

  def spec_values_are_active_options
    return if category.blank? || specs_hash.empty?

    definitions = category.effective_attribute_definitions.index_by(&:key)
    specs_hash.each do |key, raw|
      definition = definitions[key.to_s]
      next if definition.nil? || !definition.select_type?

      allowed = definition.attribute_options.select(&:active?).map(&:value)
      values = Array(raw).map(&:to_s)
      next if values.all? { |value| allowed.include?(value) }

      errors.add(:specs,
                 I18n.t("listings.errors.invalid_spec_option",
                        attribute: definition.name.presence || definition.key))
    end
  end

  def material_edit_on_published_listing?
    persisted? && status == "published" && approval_required? &&
      (changed.map(&:to_s) & MATERIAL_ATTRIBUTES).any?
  end

  def reopen_for_review_on_material_edit
    self.status = "pending_review"
  end

  def mark_submitted
    self.submitted_at = Time.current
    self.rejection_reason = nil
    self.published_at = Time.current if approval_not_required?
  end

  def mark_published
    self.published_at = Time.current
    self.rejection_reason = nil
  end

  def assign_rejection_reason(reason = nil)
    self.rejection_reason = reason if reason.present?
  end

  def rejection_reason_provided?(reason = nil)
    reason.present? || rejection_reason.present?
  end

  def mark_sold_at
    self.sold_at = Time.current
  end

  def mark_archived_at
    self.archived_at = Time.current
  end

  def mark_republished
    self.submitted_at = Time.current
    self.archived_at = nil
    self.published_at = Time.current if approval_not_required?
  end

  def remember_counter_snapshot
    @counter_snapshot = counter_state
  end

  def sync_listing_counters
    before = destroyed? ? @counter_snapshot : counter_state_before_save
    after = destroyed? ? nil : counter_state
    return if before == after

    adjust_counters(before, -1)
    adjust_counters(after, 1)
  end

  def counter_state
    { store_id: store_id, category_id: category_id,
      published: status == "published" }
  end

  def counter_state_before_save
    return if previously_new_record?

    { store_id: store_id_before_last_save,
      category_id: category_id_before_last_save,
      published: status_before_last_save == "published" }
  end

  def adjust_counters(state, delta)
    return if state.nil? || !state[:published]

    Store.update_counters(state[:store_id], listings_count: delta)
    Category.update_counters(state[:category_id], listings_count: delta)
  end
end
