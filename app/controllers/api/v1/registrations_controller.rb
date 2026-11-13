# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < BaseController
      def create
        user = User.new(user_params)
        user.terms_accepted = params.dig(:user, :terms_accepted).presence || params[:terms_accepted]
        user.save!

        if confirmation_required?(user)
          render_data({
            user: MeSerializer.new(user).serializable_hash,
            confirmation_required: true,
            message: I18n.t("api.auth.confirmation_sent", locale: error_locale)
          }, status: :created)
        else
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

      private

      def user_params
        params.require(:user).permit(
          :username, :email, :password, :password_confirmation,
          :first_name, :last_name, :phone, :locale, :country_code,
          :marketing_opt_in
        )
      end

      def confirmation_required?(user)
        !user.confirmed? && Setting.get(:api_require_confirmation, true)
      end
    end
  end
end
