# frozen_string_literal: true

class Store < ApplicationRecord
  extend FriendlyId

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes

  belongs_to :user
  belongs_to :region, optional: true

  has_one_attached :logo
  has_one_attached :banner

  has_many :listings, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :payouts, dependent: :restrict_with_error
  has_many :follows, dependent: :destroy
  has_many :followers, through: :follows, source: :follower

  friendly_id :name, use: %i[slugged history]

  enum :kind, { individual: 0, business: 1 }, scopes: false
  enum :status, { active: 0, suspended: 1 }, scopes: false

  validates :name, presence: true, length: { in: 2..60 }
  validates :description, length: { maximum: 2000 }
  validates :tax_id, presence: true, if: :business?
  validates :tax_id, spanish_tax_id: true, allow_blank: true
  validates :postal_code, format: { with: /\A\d{5}\z/ }, allow_blank: true, if: :spain?
  validates :region, :city, presence: true, on: :onboarding
  validates :postal_code, presence: true, on: :onboarding, if: :business?
  validates :user_id, uniqueness: true
  validates :logo,
            content_type: { in: IMAGE_CONTENT_TYPES, message: :invalid_image_type },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE, message: :image_too_large }
  validates :banner,
            content_type: { in: IMAGE_CONTENT_TYPES, message: :invalid_image_type },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE, message: :image_too_large }

  scope :active, -> { where(status: :active) }
  scope :verified, -> { where.not(verified_at: nil) }

  before_validation :sync_province_from_region
  before_validation :clear_business_details, unless: :business?

  validate :region_belongs_to_country

  def verified?
    verified_at.present?
  end

  # Stripe must be able to transfer funds before the store can accept orders.
  # Test and key-less development installs use the fake gateway, which needs no
  # Connect account.
  def payouts_ready?
    payouts_enabled? || Payments.fake_gateway?
  end

  private

  def spain?
    country_code == "ES"
  end

  def sync_province_from_region
    self.province = region.name if region.present?
  end

  def clear_business_details
    self.legal_name = nil
    self.tax_id = nil
    self.address_line = nil
    self.postal_code = nil
    self.phone = nil
    self.website = nil
  end

  def region_belongs_to_country
    return if region.blank? || country_code.blank?
    return if region.country_code == country_code

    errors.add(:region_id, I18n.t("stores.errors.region_country_mismatch"))
  end
end
