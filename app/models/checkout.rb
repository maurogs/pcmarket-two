# frozen_string_literal: true

class Checkout < ApplicationRecord
  STATUSES = %w[pending paid failed expired cancelled].freeze
  RESERVATION_WINDOW = 15.minutes

  belongs_to :buyer, class_name: "User", optional: true
  has_many :orders, dependent: :destroy, inverse_of: :checkout

  attr_accessor :terms_accepted

  validates :status, inclusion: { in: STATUSES }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :shipping_address, presence: true

  before_validation :set_expiry, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :expired, -> { pending.where(expires_at: ..Time.current) }

  STATUSES.each do |status_name|
    define_method("#{status_name}?") { status == status_name }
  end

  def subtotal_cents
    orders.sum(&:subtotal_cents)
  end

  def shipping_cents
    orders.sum(&:shipping_cents)
  end

  def total_cents
    orders.sum(&:total_cents)
  end

  def expired?
    pending? && expires_at.present? && expires_at <= Time.current
  end

  def recipient_email
    email.presence || buyer&.email
  end

  private

  def set_expiry
    self.expires_at ||= RESERVATION_WINDOW.from_now
  end
end
