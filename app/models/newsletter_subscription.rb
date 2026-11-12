# frozen_string_literal: true

class NewsletterSubscription < ApplicationRecord
  RATE_LIMIT = 5
  RATE_WINDOW = 1.hour

  has_secure_token :token, length: 32

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :token, presence: true, uniqueness: true

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :active, -> { confirmed.where(unsubscribed_at: nil) }

  # Double opt-in: the request only stores the address and sends the
  # confirmation email. Re-requesting an unconfirmed address resends it;
  # requesting an unsubscribed address starts the flow again.
  def self.request(email:, locale:, ip: nil)
    record = find_or_initialize_by(email: email)
    record.locale = locale.to_s if record.new_record? || record.unsubscribed_at.present?

    if rate_limited?(ip)
      record.errors.add(:base, I18n.t("newsletter.errors.rate_limited"))
      return record
    end

    if record.new_record?
      record.save
    elsif record.unsubscribed_at.present?
      record.update(unsubscribed_at: nil, confirmed_at: nil)
    end

    NewsletterMailer.confirmation(record).deliver_later if record.persisted? && !record.confirmed?
    record
  end

  def self.rate_limited?(ip)
    return false if ip.blank?

    key = "newsletter/rate/#{Digest::SHA256.hexdigest(ip.to_s)}"
    count = Rails.cache.increment(key, 1, expires_in: RATE_WINDOW)
    return false if count.nil?

    count > RATE_LIMIT
  end

  def confirm!
    return false if unsubscribed_at.present?
    return true if confirmed_at.present?

    update!(confirmed_at: Time.current)
  end

  def unsubscribe!
    update!(unsubscribed_at: Time.current)
  end

  def active?
    confirmed_at.present? && unsubscribed_at.nil?
  end

  def confirmed?
    confirmed_at.present?
  end
end
