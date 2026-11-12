# frozen_string_literal: true

module Admin
  class UserRolesController < BaseController
    def create
      user = User.find(params[:user_id])
      authorize user, :change_role?, policy_class: Admin::UserPolicy

      if Admin::ChangeUserRole.new(user: user, actor: current_user, role: params[:role]).call
        audit!(action: "user.role_changed", auditable: user, changes: { role: params[:role] })
        redirect_to admin_user_path(user), notice: t("admin.users.flash.role_changed")
      else
        redirect_to admin_user_path(user), alert: t("admin.users.flash.role_change_failed")
      end
    end
  end
end
