# frozen_string_literal: true

require "googleauth"

module Api
  module V1
    # Verifies a Google ID token against Google's published certificates. The
    # audience is the configured Android/iOS/web client id list.
    class GoogleTokenVerifier
      def self.client_ids
        values = []
        values.concat(ENV["GOOGLE_CLIENT_IDS"].to_s.split(","))
        values << ENV["GOOGLE_CLIENT_ID"]
        values << Rails.application.credentials.dig(:google, :client_id)
        values.map { |value| value.to_s.strip }.reject(&:blank?).uniq
      end

      def initialize(id_token)
        @id_token = id_token.to_s.strip
      end

      def call
        raise invalid_token if @id_token.blank?

        payload = Google::Auth::IDTokens.verify_oidc(@id_token, aud: self.class.client_ids.presence)
        raise invalid_token unless payload.is_a?(Hash)

        payload
      rescue Google::Auth::IDTokens::VerificationError,
             Google::Auth::IDTokens::KeySourceError,
             JWT::DecodeError
        raise invalid_token
      end

      private

      def invalid_token
        Api::V1::Error.unauthorized(message_key: "api.auth.invalid_google_token")
      end
    end
  end
end
