# frozen_string_literal: true

module Api
  module V1
    class OrdersController < AuthenticatedController
      def index
        authorize Order
        collection_response(
          policy_scope(Order).includes({ store: { logo_attachment: :blob } }, :review, items: :listing).recent_first,
          OrderSerializer
        )
      end

      def show
        order = current_user.orders.includes({ store: { logo_attachment: :blob } }, :review, items: :listing)
                         .find(params[:id])
        authorize order
        render_resource(order, OrderSerializer)
      end
    end
  end
end
