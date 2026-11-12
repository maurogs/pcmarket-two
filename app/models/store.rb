# frozen_string_literal: true

class Store < ApplicationRecord
  extend FriendlyId

  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes

  belongs_to :user

  has_one_attached :logo
  has_one_attached :banner

  has_many :listings, dependent: :restrict_with_error

  friendly_id :name, use: %i[slugged history]

  enum :kind, { individual: 0, business: 1 }, scopes: false
  enum :status, { active: 0, suspended: 1 }, scopes: false

  validates :name, presence: true, length: { in: 2..60 }
  validates :description, length: { maximum: 2000 }
  validates :tax_id, presence: true, if: :business?
  validates :user_id, uniqueness: true
  validates :logo,
            content_type: { in: IMAGE_CONTENT_TYPES },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE }
  validates :banner,
            content_type: { in: IMAGE_CONTENT_TYPES },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE }

  scope :active, -> { where(status: :active) }
  scope :verified, -> { where.not(verified_at: nil) }

  def verified?
    verified_at.present?
  end
end
