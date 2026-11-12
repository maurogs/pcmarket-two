# frozen_string_literal: true

class BuybackQuote < ApplicationRecord
  LIFETIME = 7.days

  belongs_to :buyback_price
  belongs_to :user, optional: true
  has_one :buyback_request, dependent: :restrict_with_error

  enum :component_type, { gpu: 0, cpu: 1 }, scopes: false

  validates :component_model, presence: true
  validates :condition, inclusion: { in: BuybackPrice::CONDITION_KEYS }
  validates :offer_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :ensure_token, on: :create
  before_validation :set_expiry, on: :create

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired? && !buyback_request.present?
  end

  private

  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end

  def set_expiry
    self.expires_at ||= LIFETIME.from_now
  end
end
