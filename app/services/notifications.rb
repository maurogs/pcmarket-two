# frozen_string_literal: true

# Persists data-only notifications. Text is rendered by the UI or the mailer,
# never stored on the row.
module Notifications
  module_function

  def record(recipient:, kind:, notifiable: nil, params: {}, preferences: nil)
    return nil if recipient.blank?
    return nil unless NotificationPreference.in_app?(recipient, kind, preferences: preferences)

    Notification.create!(
      recipient: recipient,
      kind: kind.to_s,
      notifiable: notifiable,
      params: params.deep_stringify_keys
    )
  end

  def deliver_email?(recipient, kind, preferences: nil)
    return false if recipient.blank?

    NotificationPreference.email?(recipient, kind, preferences: preferences)
  end
end
