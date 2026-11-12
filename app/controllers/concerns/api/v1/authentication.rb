# frozen_string_literal: true

module Api
  module V1
    # Bearer token authentication for the JSON API. The token is looked up by
    # its SHA256 digest; raw tokens are never persisted.
    module Authentication
      extend ActiveSupport::Concern

      BEARER_PATTERN = /\ABearer\s+(.+)\z/i

      included do
        attr_reader :current_api_session, :current_user
      end

      private

      def load_api_session
        raw_token = bearer_token
        return if raw_token.blank?

        session = ApiSession.authenticate(raw_token)
        raise Api::V1::Error.unauthorized if session.nil?

        @current_api_session = session
        @current_user = session.user
      end

      def authenticate_api_user!
        return if current_user.present?

        raise Api::V1::Error.unauthorized
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        match = header.match(BEARER_PATTERN)
        match ? match[1].strip : nil
      end
    end
  end
end
