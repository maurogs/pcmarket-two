# frozen_string_literal: true

module Admin
  class UserPasswordResetsController < BaseController
    def create
      user = User.find(params[:user_id])
      authorize user, :reset_password?, policy_class: Admin::UserPolicy

      user.send_reset_password_instructions
      audit!(action: "user.password_reset_requested", auditable: user)
      redirect_to admin_user_path(user), notice: t("admin.users.flash.password_reset_sent")
    end
  end
end
