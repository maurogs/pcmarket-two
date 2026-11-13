# frozen_string_literal: true

module Admin
  class UserDeletionsController < BaseController
    def create
      user = User.find(params[:user_id])
      authorize user, :destroy?, policy_class: Admin::UserPolicy

      result = Accounts::Delete.new(user: user).call

      if result.success?
        audit!(action: "user.deleted", auditable: user)
        redirect_to admin_user_path(user), notice: t("admin.users.flash.deleted")
      else
        redirect_to admin_user_path(user), alert: t(result.error_key)
      end
    end
  end
end
