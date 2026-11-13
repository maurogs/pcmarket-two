# frozen_string_literal: true

class OrderDeliveryConfirmationsController < ApplicationController
  before_action :authenticate_user!

  def create
    order = Order.find(params[:order_id])
    authorize order, :confirm_delivery?

    if Orders::ConfirmDelivery.new(order: order, actor: current_user).call
      redirect_to order_path(order), notice: t("orders.flash.delivery_confirmed")
    else
      redirect_to order_path(order), alert: t("orders.flash.cannot_confirm_delivery")
    end
  end
end
