# frozen_string_literal: true

module Api
  module V1
    class DeviceTokensController < AuthenticatedController
      def create
        token = DeviceToken.find_or_initialize_by(token: params[:token].to_s.strip)
        token.assign_attributes(
          user: current_user,
          api_session: current_api_session,
          platform: ApiSession.normalized_platform(params[:platform]),
          last_seen_at: Time.current
        )
        token.save!
        render_resource(token, DeviceTokenSerializer, status: :created)
      end

      def destroy
        token = current_user.device_tokens.find(params[:id])
        token.destroy!
        head :no_content
      end
    end
  end
end
