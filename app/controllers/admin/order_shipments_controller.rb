# frozen_string_literal: true

module Admin
  class OrderShipmentsController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :ship?, policy_class: Admin::OrderPolicy

      shipped = Admin::ShipOrder.new(
        order: order,
        actor: current_user,
        carrier: params[:carrier],
        tracking_number: params[:tracking_number]
      ).call

      if shipped
        audit!(action: "order.shipped", auditable: order,
               changes: { carrier: order.tracking_carrier, tracking_number: order.tracking_number })
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.shipped")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.ship_failed")
      end
    end
  end
end
