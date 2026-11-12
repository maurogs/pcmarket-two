# frozen_string_literal: true

module Account
  class ProfilesController < ApplicationController
    include BlocksImpersonation

    before_action :authenticate_user!
    skip_before_action :block_impersonated_account_change, only: :show

    def show
      authorize current_user, :show?, policy_class: AccountPolicy
      @user = current_user
    end

    def update
      authorize current_user, :update?, policy_class: AccountPolicy

      if params[:section] == "email"
        update_email
      else
        update_profile
      end
    end

    private

    def update_profile
      if current_user.update(profile_params)
        redirect_to account_profile_path(locale: current_user.locale == I18n.default_locale ? nil : current_user.locale),
                    notice: t("account.settings.profile.flash.updated")
      else
        @user = current_user
        render :show, status: :unprocessable_entity
      end
    end

    def update_email
      if current_user.update(email_params)
        redirect_to account_profile_path,
                    notice: t("account.settings.security.email_sent")
      else
        @user = current_user
        render :show, status: :unprocessable_entity
      end
    end

    def profile_params
      params.require(:user).permit(
        :first_name, :last_name, :username, :phone, :locale, :avatar
      )
    end

    def email_params
      params.require(:user).permit(:email)
    end
  end
end
