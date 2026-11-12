# frozen_string_literal: true

module Accounts
  # Signed, expiring tokens for the GDPR data-export download link.
  module ExportToken
    PURPOSE = :data_export
    EXPIRY = 7.days

    module_function

    def generate(user)
      verifier.generate({ "user_id" => user.id }, purpose: PURPOSE, expires_in: EXPIRY)
    end

    def verify(token)
      payload = verifier.verified(token, purpose: PURPOSE)
      payload && payload["user_id"]
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def verifier
      Rails.application.message_verifier(PURPOSE)
    end
  end
end
