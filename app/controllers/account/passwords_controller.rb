# frozen_string_literal: true

module Account
  class PasswordsController < ApplicationController
    before_action :authenticate_user!

    def update
      authorize current_user, :update?, policy_class: AccountPolicy

      unless current_user.provider.blank?
        redirect_to account_profile_path,
                    alert: t("account.settings.security.oauth_only")
        return
      end

      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to account_profile_path,
                    notice: t("account.settings.security.password_changed")
      else
        @user = current_user
        render "account/profiles/show", status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end
  end
end
