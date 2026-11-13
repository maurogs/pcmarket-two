# frozen_string_literal: true

module Api
  module V1
    module Sell
      class OrderShipmentsController < AuthenticatedController
        def create
          order = current_user.store.orders.find(params[:order_id])
          authorize order, :ship?, policy_class: ::Sell::OrderPolicy

          unless ::Orders::Ship.new(order: order, actor: current_user,
                                    carrier: params[:carrier],
                                    tracking_number: params[:tracking_number]).call
            raise Api::V1::Error.conflict(message_key: "sales.flash.cannot_ship")
          end

          render_resource(order.reload, OrderSerializer)
        end
      end
    end
  end
end
