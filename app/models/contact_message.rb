# frozen_string_literal: true

class ContactMessage < ApplicationRecord
  TOPICS = %w[general buying selling payments shipping account report privacy].freeze
  RATE_LIMIT = 3
  RATE_WINDOW = 1.hour

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true, length: { in: 2..80 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :topic, inclusion: { in: TOPICS }
  validates :order_number, length: { maximum: 40 }, allow_blank: true
  validates :message, presence: true, length: { in: 10..5_000 }
  validate :within_rate_limit, on: :create

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def self.recent_from?(email)
    where(email: email).where("created_at > ?", RATE_WINDOW.ago).count
  end

  # Honeypot: bots fill the hidden field, humans leave it empty.
  def spam?
    website.present?
  end

  attr_accessor :website

  private

  def within_rate_limit
    return if email.blank?
    return if self.class.recent_from?(email) < RATE_LIMIT

    errors.add(:base, I18n.t("contact.errors.rate_limited"))
  end
end
