# frozen_string_literal: true

module Admin
  class OrderDisputeResolutionsController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :resolve_dispute?, policy_class: Admin::OrderPolicy

      resolved = Admin::ResolveDispute.new(
        order: order,
        actor: current_user,
        decision: params[:decision],
        note: params[:note]
      ).call

      if resolved
        audit!(action: "order.dispute_resolved", auditable: order,
               changes: { decision: params[:decision] })
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.dispute_resolved")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.dispute_failed")
      end
    end
  end
end
