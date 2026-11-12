# frozen_string_literal: true

module Admin
  # Deliberately inherits ApplicationController: the stop action must remain
  # reachable while the session belongs to the impersonated (non-staff) user.
  class ImpersonationsController < ApplicationController
    include Admin::Auditable

    before_action :authenticate_user!
    before_action :require_admin, only: :create
    before_action :require_impersonator, only: :destroy

    def create
      target = User.find(params[:user_id])
      admin = current_user

      if target.id == admin.id || target.admin?
        redirect_to admin_user_path(target), alert: t("admin.impersonation.cannot")
        return
      end

      session[:impersonator_id] = admin.id
      sign_in(:user, target)

      AdminAuditLog.record!(
        actor: admin,
        action: "impersonation.started",
        auditable: target,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
      redirect_to root_path, notice: t("admin.impersonation.started", name: target.display_name)
    end

    def destroy
      impersonated = current_user
      admin = User.find_by(id: session.delete(:impersonator_id))

      if admin.blank?
        redirect_to root_path, alert: t("admin.impersonation.not_impersonating")
        return
      end

      sign_in(:user, admin)
      AdminAuditLog.record!(
        actor: admin,
        action: "impersonation.stopped",
        auditable: impersonated,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
      redirect_to admin_user_path(impersonated), notice: t("admin.impersonation.stopped")
    end

    private

    def require_admin
      return if current_user.admin? && !impersonating?

      raise ActiveRecord::RecordNotFound
    end

    def require_impersonator
      return if impersonating? && session[:impersonator_id].present?

      redirect_to root_path, alert: t("admin.impersonation.not_impersonating")
    end
  end
end
