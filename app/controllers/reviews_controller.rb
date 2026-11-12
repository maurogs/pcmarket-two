# frozen_string_literal: true

class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order

  def create
    @review = @order.build_review(review_params)
    @review.reviewer = current_user
    @review.store = @order.store
    authorize @review

    if @review.save
      redirect_to order_path(@order, anchor: "review"), notice: t("reviews.flash.created")
    else
      render_order
    end
  end

  def update
    @review = @order.review
    raise ActiveRecord::RecordNotFound if @review.blank?

    authorize @review
    @review.assign_attributes(review_params)

    if @review.save
      redirect_to order_path(@order, anchor: "review"), notice: t("reviews.flash.updated")
    else
      render_order
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def review_params
    params.fetch(:review, ActionController::Parameters.new).permit(:rating, :body)
  end

  def render_order
    @order = Order.find(params[:order_id])
    render "orders/show", status: :unprocessable_entity
  end
end
