# frozen_string_literal: true

module Api
  module V1
    class ReviewsController < AuthenticatedController
      def create
        order = current_user.orders.find(params[:order_id])
        review = order.build_review(review_params)
        review.reviewer = current_user
        review.store = order.store
        authorize review
        review.save!
        render_resource(review, ReviewSerializer, status: :created)
      end

      def update
        order = current_user.orders.find(params[:order_id])
        review = order.review
        raise ActiveRecord::RecordNotFound if review.blank?

        authorize review
        review.update!(review_params)
        render_resource(review, ReviewSerializer)
      end

      private

      def review_params
        params.require(:review).permit(:rating, :body)
      end
    end
  end
end
