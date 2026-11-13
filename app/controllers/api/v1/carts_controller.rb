# frozen_string_literal: true

module Api
  module V1
    class CartsController < AuthenticatedController
      def show
        cart = current_user.cart || current_user.build_cart
        authorize cart
        render_resource(cart, CartSerializer, options: { params: { cart: cart } })
      end
    end
  end
end
