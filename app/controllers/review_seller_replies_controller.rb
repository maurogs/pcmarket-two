# frozen_string_literal: true

class ReviewSellerRepliesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review

  def create
    authorize @review, :reply?

    reply = params.dig(:review, :seller_reply).presence

    if @review.update(seller_reply: reply, seller_replied_at: Time.current)
      redirect_to sell_order_path(@review.order), notice: t("reviews.flash.replied")
    else
      redirect_to sell_order_path(@review.order), alert: t("reviews.flash.reply_failed")
    end
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end
end
