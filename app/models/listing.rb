# frozen_string_literal: true

class Listing < ApplicationRecord
  include AASM
  include PgSearch::Model
  extend FriendlyId

  STATUSES = %w[draft pending_review published rejected reserved sold archived].freeze
  WIZARD_STEPS = %w[category photos details price review].freeze
  MAX_SELLER_TAGS = 5
  # Edits that require a fresh moderation pass; price, quantity and shipping
  # changes deliberately stay live.
  MATERIAL_ATTRIBUTES = %w[title description category_id specs].freeze
  SEARCH_CACHE_VERSION_KEY = "listings/version"

  belongs_to :store
  belongs_to :category
  belongs_to :region, optional: true
  belongs_to :seller, class_name: "User", foreign_key: :user_id, inverse_of: :listings

  has_many :photos, -> { order(:position, :id) },
           class_name: "ListingPhoto", dependent: :destroy, inverse_of: :listing
  has_many :listing_tags, dependent: :destroy
  has_many :tags, through: :listing_tags
  has_many :moderations, class_name: "ListingModeration", dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error

  friendly_id :slug_source, use: %i[slugged history]

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

  validates :title, presence: true, length: { in: 5..140 },
                    unless: :wizard_before_details_step?
  validates :description, presence: true, length: { in: 20..10_000 },
                          unless: :wizard_before_details_step?
  validates :slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :price_cents, presence: true,
                          numericality: { only_integer: true, greater_than: 0 },
                          unless: :wizard_before_price_step?
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                       unless: :wizard_before_price_step?
  validates :shipping_price_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :handling_days, numericality: { only_integer: true, in: 1..10 },
                            unless: :wizard_before_price_step?
  validates :views_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :favorites_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rejection_reason, presence: true, if: :rejected?
  validates :region, :city, :postal_code, presence: true, on: %i[price review]
  validate :price_within_settings
  validate :compare_at_price_above_price
  validate :country_is_launched
  validate :region_belongs_to_country
  validate :required_specs_present
  validate :spec_values_are_active_options
  validate :photos_present, on: %i[photos review]
  validate :seller_tags_within_limit
  validate :quantity_allowed_for_store, on: %i[price review]

  # Material edits of a live listing go back through moderation in the very
  # same save, so counter callbacks observe a single status change.
  before_save :reopen_for_review_on_material_edit,
              if: :material_edit_on_published_listing?

  before_destroy :remember_counter_snapshot
  after_commit :sync_listing_counters, on: %i[create update destroy]
  after_commit :bump_search_cache_version, on: %i[create update destroy]

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
      .where("listings.quantity > 0")
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
  # Card rendering needs the seller storefront (with its logo), the category,
  # the region, the product labels and every photo with its variants.
  scope :with_card_includes, lambda {
    includes(
      :category,
      :region,
      :tags,
      { store: { logo_attachment: :blob } },
      { photos: { image_attachment: :blob } }
    )
  }
  scope :with_detail_includes, lambda {
    includes(
      :category,
      :region,
      :seller,
      :tags,
      { store: { logo_attachment: :blob } },
      { photos: { image_attachment: :blob } }
    )
  }

  def self.search_cache_version
    Rails.cache.read(SEARCH_CACHE_VERSION_KEY) || 0
  end

  # Same category, price within +/- 30%, visible only.
  def self.similar_to(listing, limit: 8)
    return none if listing.price_cents.blank?

    price = listing.price_cents
    visible
      .where(category_id: listing.category_id)
      .where.not(id: listing.id)
      .where(price_cents: (price * 0.7).round..(price * 1.3).round)
      .with_card_includes
      .order(published_at: :desc, id: :desc)
      .limit(limit)
  end

  def self.more_from_seller(listing, limit: 8)
    visible
      .where(store_id: listing.store_id)
      .where.not(id: listing.id)
      .with_card_includes
      .order(published_at: :desc, id: :desc)
      .limit(limit)
  end

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

  def price=(value)
    self.price_cents = euros_to_cents(value)
  end

  def compare_at_price
    return if compare_at_price_cents.nil?

    BigDecimal(compare_at_price_cents) / 100
  end

  def compare_at_price=(value)
    self.compare_at_price_cents = euros_to_cents(value)
  end

  def shipping_price
    return if shipping_price_cents.nil?

    BigDecimal(shipping_price_cents) / 100
  end

  def shipping_price=(value)
    self.shipping_price_cents = euros_to_cents(value)
  end

  def seller_tag_ids
    tags.select(&:seller_tag?).map(&:id)
  end

  def seller_tag_ids=(ids)
    self.tag_ids = Tag.seller_tags.active.where(id: Array(ids)).pluck(:id)
  end

  # Fields the review step still needs. Each entry points at the wizard step
  # that can fix it.
  def missing_wizard_requirements
    missing = []
    missing << { step: "category", attribute: :category } if category.blank?
    missing << { step: "photos", attribute: :photos } if photos.empty?
    unless title.present? && title.length.between?(5, 140)
      missing << { step: "details", attribute: :title }
    end
    unless description.present? && description.length.between?(20, 10_000)
      missing << { step: "details", attribute: :description }
    end
    missing << { step: "details", attribute: :condition } if condition.blank?
    missing << { step: "price", attribute: :price_cents } unless price_cents.to_i.positive?
    missing << { step: "price", attribute: :region } if region.blank?
    missing << { step: "price", attribute: :city } if city.blank?
    missing << { step: "price", attribute: :postal_code } if postal_code.blank?

    if category.present?
      missing_specs = category.effective_category_attributes.select(&:required?).filter_map do |category_attribute|
        definition = category_attribute.attribute_definition
        next if spec_value_present?(definition.key)

        { step: "details", attribute: :specs, label: definition.name }
      end
      missing.concat(missing_specs)
    end

    missing
  end

  def discount_percent
    return if compare_at_price_cents.blank? || price_cents.blank?
    return if compare_at_price_cents <= price_cents

    ((compare_at_price_cents - price_cents) * 100.0 / compare_at_price_cents).round
  end

  def primary_photo
    photos.first
  end

  # Atomically takes stock out of circulation. Returns false when another
  # buyer got there first (or the listing is no longer purchasable).
  def reserve_stock!(amount)
    reserved = false

    with_lock do
      next unless published? && quantity.to_i >= amount

      self.quantity = quantity.to_i - amount
      # Single items are hidden as soon as they are taken. Multi-quantity
      # listings stay live until the last unit is reserved; at that point they
      # must leave the visible set too.
      if store.individual? || quantity.zero?
        reserve!
      else
        save!
      end
      reserved = true
    end

    reserved
  end

  # Puts reserved units back on sale. Used by failed/expired/cancelled
  # checkouts and order cancellations.
  def release_stock!(amount)
    with_lock do
      self.quantity = quantity.to_i + amount
      if reserved? && quantity.positive?
        release!
      elsif sold?
        self.status = "published"
        self.sold_at = nil
        save!
      else
        save!
      end
    end
  end

  # Keeps multi-quantity listings live until the last unit is gone and then
  # moves single items from reserved to sold.
  def mark_sold_after_sale!
    with_lock do
      next if sold? || archived?

      mark_sold! if reserved? || (published? && quantity.to_i.zero?)
    end
  end

  # Visible to everybody: published, active storefront and active seller.
  def publicly_visible?
    published? && store&.active? && seller && !seller.banned? && !seller.soft_deleted?
  end

  # Owners, moderators and admins may inspect their own non-public listings.
  def visible_to?(user)
    return true if owner_or_staff?(user)

    publicly_visible?
  end

  def owner_or_staff?(user)
    user.present? && (user_id == user.id || user.admin? || user.moderator?)
  end

  # Called when a photo is added or removed: photos are a material edit.
  def reopen_for_review_after_photo_change!
    return unless persisted? && status == "published" && approval_required?

    update!(status: "pending_review")
  end

  def slug_source
    base = title.presence || category&.name.presence || "listing"
    "#{base}-#{SecureRandom.hex(3)}"
  end

  private

  def euros_to_cents(value)
    return if value.blank?

    (BigDecimal(value.to_s) * 100).round
  rescue ArgumentError, TypeError
    nil
  end

  def wizard_context
    validation_context&.to_s
  end

  def wizard_before_details_step?
    wizard_context_before?("details")
  end

  def wizard_before_price_step?
    wizard_context_before?("price")
  end

  def wizard_context_before?(step)
    return false unless WIZARD_STEPS.include?(wizard_context)

    WIZARD_STEPS.index(wizard_context) < WIZARD_STEPS.index(step)
  end

  def wizard_context_at_or_after?(step)
    return false unless WIZARD_STEPS.include?(wizard_context)

    WIZARD_STEPS.index(wizard_context) >= WIZARD_STEPS.index(step)
  end

  def specs_hash
    (specs || {}).with_indifferent_access
  end

  def spec_value_present?(key)
    value = specs_hash[key]
    value.is_a?(Array) ? value.any?(&:present?) : value.present?
  end

  def price_within_settings
    return if wizard_before_price_step?
    return if price_cents.blank? || !price_cents.is_a?(Numeric)

    min = Setting.get(:min_listing_price, 1).to_i * 100
    max = Setting.get(:max_listing_price, 50_000).to_i * 100
    return if price_cents.between?(min, max)

    errors.add(:price_cents,
               I18n.t("listings.errors.price_out_of_range",
                      min: min / 100, max: max / 100))
  end

  def compare_at_price_above_price
    return if wizard_before_price_step?
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
    return if draft? && !wizard_context_at_or_after?("details")

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

  def photos_present
    return if photos.any?

    errors.add(:photos, I18n.t("listings.errors.photos_required"))
  end

  def seller_tags_within_limit
    count = tags.select(&:seller_tag?).size
    return if count <= MAX_SELLER_TAGS

    errors.add(:tags,
               I18n.t("listings.errors.too_many_seller_tags", max: MAX_SELLER_TAGS))
  end

  def quantity_allowed_for_store
    return unless store&.individual?
    return if quantity.to_i == 1

    errors.add(:quantity, I18n.t("listings.errors.quantity_individual"))
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

  def bump_search_cache_version
    Rails.cache.write(SEARCH_CACHE_VERSION_KEY, Time.current.to_f)
  end
end
