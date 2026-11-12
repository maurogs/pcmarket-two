# frozen_string_literal: true

class OrderCancellationsController < ApplicationController
  before_action :authenticate_user!

  def create
    order = Order.find(params[:order_id])
    authorize order, :cancel?

    if Orders::Cancel.new(order: order, actor: current_user, reason: params[:reason]).call
      redirect_to order_path(order), notice: t("orders.flash.cancelled")
    else
      redirect_to order_path(order), alert: t("orders.flash.cannot_cancel")
    end
  end
end
