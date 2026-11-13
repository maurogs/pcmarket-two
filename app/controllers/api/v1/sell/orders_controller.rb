# frozen_string_literal: true

module Api
  module V1
    module Sell
      class OrdersController < AuthenticatedController
        before_action :ensure_store

        def index
          authorize Order, :index?, policy_class: ::Sell::OrderPolicy
          collection = ::Sell::OrderCollection.new(
            user: current_user, params: request.query_parameters
          ).call
          pagy, records = paginate(collection.orders)

          set_pagination_headers(pagy)
          render_collection(
            records, OrderSerializer,
            meta: collection_meta(pagy, extra: { tab: collection.tab })
          )
        end

        def show
          order = current_user.store.orders.includes({ store: { logo_attachment: :blob } }, :review, items: :listing)
                          .find(params[:id])
          authorize order, policy_class: ::Sell::OrderPolicy
          render_resource(order, OrderSerializer)
        end

        private

        def ensure_store
          return if current_user.store.present?

          raise Api::V1::Error.forbidden(message_key: "sell.errors.store_required")
        end
      end
    end
  end
end
