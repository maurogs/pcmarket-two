# frozen_string_literal: true

require "digest"

# A long-lived, revocable token pair for native app sessions.
#
# Only SHA256 digests are persisted. The raw access and refresh tokens are
# returned exactly once, when the session is issued or rotated.
class ApiSession < ApplicationRecord
  ACCESS_TTL = 30.days
  REFRESH_TTL = 90.days
  USAGE_THROTTLE = 5.minutes
  PLATFORMS = %w[ios android other].freeze

  belongs_to :user
  has_many :device_tokens, dependent: :nullify

  validates :token_digest, :refresh_token_digest, presence: true, uniqueness: true
  validates :platform, inclusion: { in: PLATFORMS }
  validates :device_name, length: { maximum: 120 }, allow_blank: true
  validates :app_version, length: { maximum: 40 }, allow_blank: true
  validates :expires_at, :refresh_expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("refresh_expires_at > ?", Time.current) }
  scope :recent_first, -> { order(last_used_at: :desc, id: :desc) }

  # Issues a new session and returns [session, access_token, refresh_token].
  def self.issue!(user:, device_name: nil, platform: "other", app_version: nil, ip: nil)
    access_token = SecureRandom.hex(32)
    refresh_token = SecureRandom.hex(32)
    now = Time.current

    session = create!(
      user: user,
      token_digest: digest(access_token),
      refresh_token_digest: digest(refresh_token),
      device_name: device_name,
      platform: normalized_platform(platform),
      app_version: app_version,
      last_used_at: now,
      expires_at: ACCESS_TTL.from_now,
      refresh_expires_at: REFRESH_TTL.from_now,
      ip: ip
    )

    [ session, access_token, refresh_token ]
  end

  # Finds the session for a raw bearer token. Expired, revoked and inactive
  # user sessions are rejected. The sliding expiry is persisted at most once
  # every five minutes.
  def self.authenticate(raw_token)
    token = raw_token.to_s.strip
    return if token.blank?

    session = where(token_digest: digest(token), revoked_at: nil)
              .where("expires_at > ?", Time.current)
              .first
    return if session.nil?
    return unless session.user&.active_for_authentication?
    return if Setting.get(:api_require_confirmation, true) && !session.user.confirmed?

    session.touch_usage!
    session
  end

  # Rotates the token pair in place. A refresh token can be used only once:
  # the previous digest no longer resolves after this call.
  def self.refresh!(raw_refresh_token, ip: nil)
    refresh_token = raw_refresh_token.to_s.strip
    return if refresh_token.blank?

    session = where(refresh_token_digest: digest(refresh_token), revoked_at: nil).first
    return if session.nil?

    new_access = SecureRandom.hex(32)
    new_refresh = SecureRandom.hex(32)
    rotated = false

    session.with_lock do
      next if session.revoked_at.present?
      next unless session.refresh_expires_at.present? && session.refresh_expires_at > Time.current
      next unless session.user&.active_for_authentication?

      now = Time.current
      session.update_columns(
        token_digest: digest(new_access),
        refresh_token_digest: digest(new_refresh),
        last_used_at: now,
        expires_at: ACCESS_TTL.from_now,
        refresh_expires_at: REFRESH_TTL.from_now,
        ip: ip.presence || session.ip,
        updated_at: now
      )
      rotated = true
    end

    rotated ? [ session.reload, new_access, new_refresh ] : nil
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.normalized_platform(value)
    platform = value.to_s.downcase
    PLATFORMS.include?(platform) ? platform : "other"
  end

  def revoke!
    return if revoked_at.present?

    update_columns(revoked_at: Time.current, updated_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  # Persists the sliding expiry and last-used timestamp at most every five
  # minutes, keeping authentication to a single indexed read in the common case.
  def touch_usage!
    now = Time.current
    stale_usage = last_used_at.blank? || last_used_at <= USAGE_THROTTLE.ago
    expiring = expires_at.blank? || expires_at <= ACCESS_TTL.from_now - 1.minute
    return unless stale_usage || expiring

    update_columns(last_used_at: now, expires_at: ACCESS_TTL.from_now, updated_at: now)
  end
end
