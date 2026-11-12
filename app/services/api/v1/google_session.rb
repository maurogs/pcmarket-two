# frozen_string_literal: true

require "omniauth"

module Api
  module V1
    # Turns a verified Google ID token into the same OmniAuth hash used by the
    # web flow, then reuses Users::FromOmniauth for linking/creation rules.
    class GoogleSession
      def initialize(id_token)
        @id_token = id_token
      end

      def call
        payload = GoogleTokenVerifier.new(@id_token).call
        raise unverified_email unless email_verified?(payload)

        user = User.from_omniauth(auth_hash(payload))
        raise_api_error_for(user)
        user
      end

      private

      def auth_hash(payload)
        OmniAuth::AuthHash.new(
          provider: "google_oauth2",
          uid: payload["sub"].to_s,
          info: {
            email: payload["email"].to_s.downcase,
            first_name: payload["given_name"],
            last_name: payload["family_name"],
            nickname: payload["name"],
            email_verified: true
          },
          extra: {
            raw_info: {
              email: payload["email"].to_s.downcase,
              email_verified: true,
              name: payload["name"]
            }
          }
        )
      end

      def email_verified?(payload)
        ActiveModel::Type::Boolean.new.cast(payload["email_verified"]).present?
      end

      def unverified_email
        Api::V1::Error.forbidden(message_key: "api.auth.email_unverified")
      end

      def raise_api_error_for(user)
        return if user.errors.empty? && user.persisted? && !user.banned? && !user.soft_deleted?

        if user.banned?
          raise Api::V1::Error.forbidden(message_key: "api.auth.banned")
        elsif user.soft_deleted?
          raise Api::V1::Error.forbidden(message_key: "api.auth.deleted")
        elsif user.errors.any?
          details = user.errors.to_hash(true).transform_keys(&:to_s)
          raise Api::V1::Error.forbidden(message_key: "api.auth.email_unverified",
                                         details: details)
        else
          raise Api::V1::Error.forbidden
        end
      end
    end
  end
end
