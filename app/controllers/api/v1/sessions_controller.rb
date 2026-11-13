# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      before_action :authenticate_api_user!, only: %i[index destroy]

      def index
        sessions = current_user.api_sessions.active.recent_first
        pagy, records = paginate(sessions)
        set_pagination_headers(pagy)
        render_collection(
          records, ApiSessionSerializer,
          meta: collection_meta(pagy),
          options: { params: { current_session_id: current_api_session.id } }
        )
      end

      def create
        user = User.find_by(email: params[:email].to_s.strip.downcase)
        unless user.present? && user.valid_password?(params[:password].to_s)
          raise Api::V1::Error.unauthorized(message_key: "api.auth.invalid_credentials")
        end

        reject_inactive_user!(user)
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

      def destroy
        session = current_user.api_sessions.find(params[:id])
        session.revoke!
        head :no_content
      end
    end
  end
end
