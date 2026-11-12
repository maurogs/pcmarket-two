# frozen_string_literal: true

module Api
  module V1
    class GoogleSessionsController < BaseController
      def create
        user = GoogleSession.new(params[:id_token]).call
        session, access_token, refresh_token = ApiSession.issue!(
          user: user,
          device_name: params[:device_name],
          platform: params[:platform],
          app_version: params[:app_version],
          ip: request.remote_ip
        )

        render_data(session_payload(user, session, access_token, refresh_token),
                    status: :created)
      end
    end
  end
end
