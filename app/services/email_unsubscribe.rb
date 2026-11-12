# frozen_string_literal: true

# Signed, expiring-free unsubscribe tokens for alert emails. The token carries
# the minimum data needed to turn off a kind of email or a saved search.
module EmailUnsubscribe
  PURPOSE = :email_unsubscribe
  MAX_AGE = 90.days

  module_function

  def token(user:, saved_search: nil, kind: nil)
    verifier.generate(
      {
        "user_id" => user.id,
        "saved_search_id" => saved_search&.id,
        "kind" => kind&.to_s
      },
      expires_in: MAX_AGE
    )
  end

  def verify(token)
    return nil if token.blank?

    data = verifier.verify(token)
    data.is_a?(Hash) ? data.stringify_keys : nil
  rescue ActiveSupport::MessageVerifier::InvalidSignature,
         ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def apply(data)
    return false unless data.respond_to?(:to_h)

    data = data.to_h.stringify_keys
    user = User.find_by(id: data["user_id"])
    return false if user.blank?

    if data["saved_search_id"].present?
      saved_search = user.saved_searches.find_by(id: data["saved_search_id"])
      saved_search&.update(email_alerts: false)
    else
      kinds = data["kind"].present? ? [ data["kind"].to_s ] : Notification::ALERT_KINDS
      kinds.each { |kind| disable_email(user, kind) }
    end

    true
  end

  def verifier
    Rails.application.message_verifier(PURPOSE)
  end

  def disable_email(user, kind)
    return unless Notification::KINDS.include?(kind)

    preference = user.notification_preferences.find_or_initialize_by(kind: kind)
    preference.in_app = true if preference.new_record?
    preference.email = false
    preference.save!
  end
end
