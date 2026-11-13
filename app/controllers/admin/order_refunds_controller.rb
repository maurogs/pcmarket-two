# frozen_string_literal: true

module Admin
  class OrderRefundsController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :refund?, policy_class: Admin::OrderPolicy

      amount_cents = (BigDecimal(params[:amount].to_s) * 100).round
      refunded = Admin::PartialRefund.new(
        order: order, actor: current_user, amount_cents: amount_cents
      ).call

      if refunded
        audit!(action: "order.partial_refunded", auditable: order,
               changes: { amount_cents: amount_cents })
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.refunded")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.refund_failed")
      end
    rescue ArgumentError, TypeError
      redirect_to admin_order_path(order), alert: t("admin.orders.flash.refund_failed")
    end
  end
end
