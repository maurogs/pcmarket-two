# frozen_string_literal: true

module Admin
  class OrderCancellationsController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :cancel?, policy_class: Admin::OrderPolicy

      if Admin::CancelOrder.new(order: order, actor: current_user, reason: params[:reason]).call
        audit!(action: "order.cancelled", auditable: order, changes: { reason: params[:reason] })
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.cancelled")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.cancel_failed")
      end
    end
  end
end
