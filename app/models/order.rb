# frozen_string_literal: true

class Order < ApplicationRecord
  include AASM

  STATUSES = %w[pending_payment paid shipped delivered completed cancelled refunded disputed].freeze
  CARRIERS = %w[correos seur mrw gls dhl ups nacex ctt other].freeze

  belongs_to :checkout
  belongs_to :buyer, class_name: "User", optional: true
  belongs_to :store

  has_many :items, class_name: "OrderItem", dependent: :destroy, inverse_of: :order
  has_many :events, class_name: "OrderEvent", dependent: :destroy, inverse_of: :order
  has_many :notes, class_name: "OrderNote", dependent: :destroy, inverse_of: :order
  has_one :payout, dependent: :destroy
  has_one :review, dependent: :destroy

  enum :fulfilment, { shipping: 0, local_pickup: 1 }, prefix: :fulfilment

  validates :status, inclusion: { in: STATUSES }
  validates :number, uniqueness: true, allow_nil: true
  validates :subtotal_cents, :shipping_cents, :commission_cents, :total_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  after_create :assign_number

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :for_buyer, ->(user) { where(buyer_id: user) }

  aasm column: :status, whiny_transitions: false do
    state :pending_payment, initial: true
    state :paid
    state :shipped
    state :delivered
    state :completed
    state :cancelled
    state :refunded
    state :disputed

    event :pay do
      before { self.paid_at = Time.current }
      transitions from: :pending_payment, to: :paid
    end

    event :ship do
      before { self.shipped_at = Time.current }
      transitions from: :paid, to: :shipped, guard: :shipping_details_ready?
    end

    event :confirm_delivery do
      before :mark_delivered
      transitions from: :shipped, to: :delivered
    end

    event :complete do
      before { self.completed_at = Time.current }
      transitions from: :delivered, to: :completed
    end

    event :cancel do
      before { self.cancelled_at = Time.current }
      transitions from: %i[pending_payment paid], to: :cancelled
    end

    event :refund do
      transitions from: %i[paid shipped delivered completed disputed], to: :refunded
    end

    event :open_dispute do
      transitions from: %i[paid shipped delivered completed], to: :disputed
    end

    # Staff decision on a dispute: release the funds to the seller.
    event :resolve do
      before { self.completed_at ||= Time.current }
      transitions from: :disputed, to: :completed
    end
  end

  # Commission is charged only when both the feature flag and the site
  # setting are enabled. It is frozen on the order row at checkout time.
  def self.commission_for(subtotal_cents)
    return 0 unless Flipper.enabled?(:commissions)
    return 0 unless ActiveModel::Type::Boolean.new.cast(Setting.get(:commission_enabled))

    percent = Setting.get(:commission_percent, 0).to_d
    (subtotal_cents.to_i * percent / 100).round
  end

  def seller
    store.user
  end

  def cancellable?
    may_cancel?
  end

  def shippable?
    paid?
  end

  def buyer_protection_active?
    buyer_protection_ends_at.present? && buyer_protection_ends_at > Time.current
  end

  # A buyer may leave one review after delivery, for 60 days.
  def reviewable?
    return false unless delivered? || completed?
    return false if delivered_at.blank?
    return false if delivered_at < Review::REVIEW_WINDOW.ago

    review.nil? || review.new_record?
  end

  def review_window_closes_at
    delivered_at.present? ? delivered_at + Review::REVIEW_WINDOW : nil
  end

  def shipping_details_ready?
    return true if fulfilment_local_pickup?

    tracking_carrier.present? && tracking_number.present?
  end

  private

  def assign_number
    update_column(:number, "PCM-#{created_at.year}-#{format('%06d', id)}")
  end

  def mark_delivered
    now = Time.current
    self.delivered_at = now
    self.buyer_protection_ends_at = now + Setting.get(:buyer_protection_days, 2).to_i.days
  end
end
