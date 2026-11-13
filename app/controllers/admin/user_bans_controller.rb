# frozen_string_literal: true

module Admin
  class UserBansController < BaseController
    def create
      user = User.find(params[:user_id])
      authorize user, :ban?, policy_class: Admin::UserPolicy

      if Admin::BanUser.new(user: user, actor: current_user, reason: params[:reason]).call
        audit!(action: "user.banned", auditable: user, changes: { reason: params[:reason] })
        redirect_to admin_user_path(user), notice: t("admin.users.flash.banned")
      else
        redirect_to admin_user_path(user), alert: t("admin.users.flash.ban_failed")
      end
    end

    def destroy
      user = User.find(params[:user_id])
      authorize user, :unban?, policy_class: Admin::UserPolicy

      Admin::BanUser.unban(user)
      audit!(action: "user.unbanned", auditable: user)
      redirect_to admin_user_path(user), notice: t("admin.users.flash.unbanned")
    end
  end
end
