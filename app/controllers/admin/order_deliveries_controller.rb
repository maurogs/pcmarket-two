# frozen_string_literal: true

module Admin
  class OrderDeliveriesController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :deliver?, policy_class: Admin::OrderPolicy

      if Admin::DeliverOrder.new(order: order, actor: current_user).call
        audit!(action: "order.delivered", auditable: order)
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.delivered")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.deliver_failed")
      end
    end
  end
end
