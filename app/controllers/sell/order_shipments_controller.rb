# frozen_string_literal: true

module Sell
  class OrderShipmentsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_store
    before_action :set_order

    def create
      authorize @order, :ship?, policy_class: Sell::OrderPolicy

      if Orders::Ship.new(order: @order,
                          actor: current_user,
                          carrier: params[:carrier],
                          tracking_number: params[:tracking_number]).call
        redirect_to sell_order_path(@order), notice: t("sales.flash.shipped")
      else
        redirect_to sell_order_path(@order), alert: t("sales.flash.cannot_ship")
      end
    end

    private

    def set_order
      @order = current_user.store.orders.find(params[:order_id])
    end

    def ensure_store
      return if current_user.store.present?

      redirect_to new_store_path, alert: t("sell.errors.store_required")
    end
  end
end
