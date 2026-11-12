# frozen_string_literal: true

module Admin
  class UserConfirmationResendsController < BaseController
    def create
      user = User.find(params[:user_id])
      authorize user, :resend_confirmation?, policy_class: Admin::UserPolicy

      if user.confirmed_at.nil?
        user.resend_confirmation_instructions
        audit!(action: "user.confirmation_resent", auditable: user)
        redirect_to admin_user_path(user), notice: t("admin.users.flash.confirmation_resent")
      else
        redirect_to admin_user_path(user), alert: t("admin.users.flash.already_confirmed")
      end
    end
  end
end
