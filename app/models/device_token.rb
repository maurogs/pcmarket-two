# frozen_string_literal: true

# A push-notification registration for one physical device. Sending is not
# implemented yet; the row is the durable link an APNs/FCM delivery adapter
# will use in a later phase.
class DeviceToken < ApplicationRecord
  PLATFORMS = ApiSession::PLATFORMS

  belongs_to :user
  belongs_to :api_session, optional: true

  normalizes :token, with: ->(token) { token.to_s.strip }

  validates :token, presence: true, uniqueness: true, length: { maximum: 512 }
  validates :platform, inclusion: { in: PLATFORMS }

  before_validation :stamp_last_seen

  private

  def stamp_last_seen
    self.last_seen_at ||= Time.current
  end
end
