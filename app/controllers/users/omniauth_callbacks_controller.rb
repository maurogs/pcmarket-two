# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      user = User.from_omniauth(request.env["omniauth.auth"])

      if user.errors.any?
        redirect_to new_user_session_path,
                    alert: t("auth.omniauth_email_not_verified")
      elsif user.active_for_authentication?
        set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
        sign_in_and_redirect user, event: :authentication
      else
        redirect_to new_user_session_path,
                    alert: t("devise.failure.#{user.inactive_message}")
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_user_registration_path,
                  alert: e.record.errors.full_messages.to_sentence
    end

    def failure
      redirect_to new_user_session_path, alert: t("auth.omniauth_failure")
    end
  end
end
