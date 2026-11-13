# frozen_string_literal: true

module Account
  class DeletionsController < ApplicationController
    include BlocksImpersonation

    before_action :authenticate_user!

    def create
      authorize current_user, :destroy?, policy_class: AccountPolicy

      unless confirmation_valid?
        redirect_to account_profile_path,
                    alert: t("account.deletion.invalid_confirmation")
        return
      end

      result = Accounts::Delete.new(user: current_user).call

      if result.success?
        sign_out(current_user)
        redirect_to root_path, notice: t("account.deletion.flash.deleted")
      else
        redirect_to account_profile_path, alert: t(result.error_key)
      end
    end

    private

    def confirmation_valid?
      if current_user.oauth_only?
        params[:username].to_s == current_user.username
      else
        current_user.valid_password?(params[:current_password])
      end
    end
  end
end
