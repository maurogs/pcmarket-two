# frozen_string_literal: true

module Api
  module V1
    module Sell
      class OrderCancellationsController < AuthenticatedController
        def create
          order = current_user.store.orders.find(params[:order_id])
          authorize order, :cancel?, policy_class: ::Sell::OrderPolicy

          unless ::Orders::Cancel.new(order: order, actor: current_user,
                                      reason: params[:reason]).call
            raise Api::V1::Error.conflict(message_key: "sales.flash.cannot_cancel")
          end

          render_resource(order.reload, OrderSerializer)
        end
      end
    end
  end
end
