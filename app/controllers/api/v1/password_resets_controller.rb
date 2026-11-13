# frozen_string_literal: true

module Api
  module V1
    class PasswordResetsController < BaseController
      def create
        user = User.find_by(email: params[:email].to_s.strip.downcase)
        if user.present? && !user.banned? && !user.soft_deleted?
          locale = Localization.normalize(user.locale) || I18n.default_locale
          I18n.with_locale(locale) { user.send_reset_password_instructions }
        end

        render_data({ message: I18n.t("api.auth.password_reset_sent", locale: error_locale) },
                    status: :accepted)
      end
    end
  end
end
