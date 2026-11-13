# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def sign_up_params
      params.require(:user).permit(
        :username, :email, :password, :password_confirmation,
        :first_name, :last_name, :phone, :locale, :country_code,
        :marketing_opt_in, :terms_accepted
      )
    end

    def account_update_params
      params.require(:user).permit(
        :username, :email, :password, :password_confirmation, :current_password,
        :first_name, :last_name, :phone, :locale, :country_code,
        :marketing_opt_in, :avatar
      )
    end
  end
end
