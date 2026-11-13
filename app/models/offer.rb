# frozen_string_literal: true

class Offer < ApplicationRecord
  include AASM

  LIFETIME = 48.hours
  MIN_PRICE_RATIO = 0.5

  STATUSES = %w[pending accepted declined countered expired withdrawn].freeze

  belongs_to :listing
  belongs_to :buyer, class_name: "User"
  belongs_to :conversation
  belongs_to :offerer, class_name: "User"
  belongs_to :counter_offer, class_name: "Offer", optional: true
  has_one :counter, class_name: "Offer", foreign_key: :counter_offer_id, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_within_listing_bounds
  validate :buyer_is_not_seller
  validate :single_pending_offer, on: :create, unless: :counter_offer_id?
  validate :counter_belongs_to_same_listing, if: :counter_offer_id?

  before_validation :set_expiry, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :for_user, lambda { |user|
    where(buyer_id: user.id).or(where(offerer_id: user.id))
  }
  scope :recent, -> { order(created_at: :desc, id: :desc) }
  scope :expiring_before, ->(time) { pending.where(expires_at: ..time) }
  scope :due, -> { pending.where(expires_at: ..Time.current) }

  aasm column: :status, whiny_transitions: false do
    state :pending, initial: true
    state :accepted
    state :declined
    state :countered
    state :expired
    state :withdrawn

    event :accept do
      transitions from: :pending, to: :accepted
    end

    event :decline do
      transitions from: :pending, to: :declined
    end

    event :mark_countered do
      transitions from: :pending, to: :countered
    end

    event :expire do
      transitions from: :pending, to: :expired
    end

    event :withdraw do
      transitions from: :pending, to: :withdrawn
    end
  end

  def self.cents_from_amount(value)
    return if value.blank?

    (BigDecimal(value.to_s) * 100).round
  rescue ArgumentError, TypeError
    nil
  end

  def seller_side?
    offerer_id != buyer_id
  end

  def recipient
    seller_side? ? buyer : listing.seller
  end

  def expired_by_time?
    expires_at.present? && expires_at <= Time.current
  end

  def expiring_soon?
    pending? && expires_at.present? && expires_at <= 6.hours.from_now
  end

  def amount
    return if amount_cents.nil?

    BigDecimal(amount_cents) / 100
  end

  def amount=(value)
    self.amount_cents = (BigDecimal(value.to_s) * 100).round
  rescue ArgumentError, TypeError
    self.amount_cents = nil
  end

  def acceptable_by?(user)
    pending? && !expired_by_time? && recipient&.id == user&.id
  end

  # An accepted offer can only be used by the buyer who made it, before it
  # expires, and for the listing it belongs to.
  def redeemable_by?(user, listing: self.listing)
    accepted? && !expired_by_time? && buyer_id == user&.id && listing&.id == listing_id
  end

  private

  def set_expiry
    self.expires_at ||= LIFETIME.from_now
  end

  def amount_within_listing_bounds
    return if amount_cents.blank? || listing&.price_cents.blank?

    price = listing.price_cents
    minimum = (price * MIN_PRICE_RATIO).round
    return if amount_cents >= minimum && amount_cents < price

    errors.add(:amount_cents,
               I18n.t("offers.errors.amount_range",
                      min: minimum / 100,
                      max: price / 100))
  end

  def buyer_is_not_seller
    return if buyer_id.blank? || listing&.user_id.blank?
    return if buyer_id != listing.user_id

    errors.add(:buyer_id, I18n.t("offers.errors.self"))
  end

  def single_pending_offer
    return if listing_id.blank? || buyer_id.blank?

    exists = self.class.pending.where(listing_id: listing_id, buyer_id: buyer_id).exists?
    return unless exists

    errors.add(:base, I18n.t("offers.errors.pending_exists"))
  end

  def counter_belongs_to_same_listing
    return if counter_offer.blank?

    return if counter_offer.listing_id == listing_id && counter_offer.buyer_id == buyer_id

    errors.add(:counter_offer_id, I18n.t("offers.errors.counter_mismatch"))
  end
end
