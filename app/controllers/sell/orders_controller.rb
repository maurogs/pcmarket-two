# frozen_string_literal: true

module Sell
  class OrdersController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_store

    def index
      authorize Order, :index?, policy_class: Sell::OrderPolicy
      @collection = Sell::OrderCollection.new(user: current_user, params: params).call
    end

    def show
      @order = current_user.store.orders.find(params[:id])
      authorize @order, policy_class: Sell::OrderPolicy
      @review = @order.review
    end

    private

    def ensure_store
      return if current_user.store.present?

      redirect_to new_store_path, alert: t("sell.errors.store_required")
    end
  end
end
