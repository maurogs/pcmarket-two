# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize Order
    @orders = policy_scope(Order).includes(:store, items: :listing).recent_first
  end

  def show
    @order = Order.find(params[:id])
    authorize @order
    @review = @order.review ||
              Review.new(order: @order, reviewer: @order.buyer, store: @order.store)
  end
end
