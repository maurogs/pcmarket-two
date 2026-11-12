# frozen_string_literal: true

module Admin
  class OrderCompletionsController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :complete?, policy_class: Admin::OrderPolicy

      if Orders::Complete.new(order: order).call
        audit!(action: "order.completed", auditable: order)
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.completed")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.complete_failed")
      end
    end
  end
end
