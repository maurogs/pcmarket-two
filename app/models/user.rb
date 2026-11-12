# frozen_string_literal: true

class User < ApplicationRecord
  USERNAME_FORMAT = /\A[a-zA-Z0-9_-]+\z/
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_one_attached :avatar
  has_one :store, dependent: :destroy

  has_many :listings, foreign_key: :user_id,
                      inverse_of: :seller, dependent: :restrict_with_error
  has_many :listing_moderations, foreign_key: :moderator_id,
                                 inverse_of: :moderator, dependent: :restrict_with_error

  has_one :cart, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :orders, foreign_key: :buyer_id, inverse_of: :buyer, dependent: :nullify
  has_many :checkouts, foreign_key: :buyer_id, inverse_of: :buyer, dependent: :nullify

  enum :role, { user: 0, moderator: 1, admin: 2 }, scopes: false

  # Virtual attribute backing the sign-up terms checkbox.
  attr_accessor :terms_accepted

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :username, with: ->(username) { username.to_s.strip }

  validates :username, presence: true,
                       length: { in: 3..30 },
                       format: { with: USERNAME_FORMAT },
                       uniqueness: { case_sensitive: false }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :country_code, presence: true,
                           length: { is: 2 },
                           format: { with: /\A[A-Z]{2}\z/ }
  validates :terms_accepted, acceptance: { allow_nil: false }, on: :create
  validates :avatar,
            content_type: { in: AVATAR_CONTENT_TYPES },
            size: { less_than_or_equal_to: AVATAR_MAX_SIZE }

  before_save :record_terms_acceptance

  scope :active, -> { where(banned_at: nil, deleted_at: nil) }

  def self.from_omniauth(auth)
    Users::FromOmniauth.new(auth).call
  end

  def banned?
    banned_at.present?
  end

  def soft_deleted?
    deleted_at.present?
  end

  def active_for_authentication?
    super && !banned? && !soft_deleted?
  end

  def inactive_message
    return :banned if banned?
    return :deleted if soft_deleted?

    super
  end

  def display_name
    [ first_name, last_name ].compact_blank.join(" ").presence || username
  end

  private

  def record_terms_acceptance
    return unless ActiveModel::Type::Boolean.new.cast(terms_accepted)

    self.terms_accepted_at ||= Time.current
  end
end
