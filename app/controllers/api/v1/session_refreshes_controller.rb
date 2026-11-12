# frozen_string_literal: true

module Api
  module V1
    class SessionRefreshesController < BaseController
      def create
        result = ApiSession.refresh!(params[:refresh_token], ip: request.remote_ip)
        raise Api::V1::Error.unauthorized(message_key: "api.auth.invalid_refresh_token") if result.nil?

        session, access_token, refresh_token = result
        render_data(session_payload(session.user, session, access_token, refresh_token))
      end
    end
  end
end
