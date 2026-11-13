# frozen_string_literal: true

module Admin
  class UserConfirmationsController < BaseController
    def create
      user = User.find(params[:user_id])
      authorize user, :confirm?, policy_class: Admin::UserPolicy

      if user.confirmed_at.nil? || user.unconfirmed_email.present?
        user.confirm
        audit!(action: "user.confirmed", auditable: user)
        redirect_to admin_user_path(user), notice: t("admin.users.flash.confirmed")
      else
        redirect_to admin_user_path(user), alert: t("admin.users.flash.already_confirmed")
      end
    end
  end
end
