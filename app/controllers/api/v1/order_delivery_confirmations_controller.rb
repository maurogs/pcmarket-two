# frozen_string_literal: true

module Api
  module V1
    class OrderDeliveryConfirmationsController < AuthenticatedController
      def create
        order = current_user.orders.find(params[:order_id])
        authorize order, :confirm_delivery?

        unless Orders::ConfirmDelivery.new(order: order, actor: current_user).call
          raise Api::V1::Error.conflict(message_key: "orders.flash.cannot_confirm_delivery")
        end

        render_resource(order.reload, OrderSerializer)
      end
    end
  end
end
