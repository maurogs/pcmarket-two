# frozen_string_literal: true

module Api
  module V1
    class CartItemsController < AuthenticatedController
      def create
        listing = Listing.with_card_includes.friendly.find(params[:listing_id])
        cart = current_user.cart || current_user.create_cart!
        authorize cart, :update?

        result = Carts::AddItem.new(
          cart: cart,
          listing: listing,
          quantity: params.fetch(:quantity, 1).to_i,
          offer: offer_param
        ).call

        raise Api::V1::Error.validation_failed(details: { base: result.errors }) unless result.success?

        render_resource(result.item.reload, CartItemSerializer, status: :created,
                        options: { params: { user: current_user } })
      end

      def update
        cart = current_user.cart
        item = cart&.items&.find(params[:id])
        raise ActiveRecord::RecordNotFound if item.nil?

        authorize item, :update?
        result = Carts::UpdateItem.new(item: item,
                                       quantity: params.fetch(:quantity, 1).to_i).call

        unless result.success?
          raise Api::V1::Error.validation_failed(details: { base: result.errors })
        end

        if result.removed
          render_data({ removed: true })
        else
          render_resource(result.item.reload, CartItemSerializer,
                          options: { params: { user: current_user } })
        end
      end

      def destroy
        cart = current_user.cart
        item = cart&.items&.find(params[:id])
        raise ActiveRecord::RecordNotFound if item.nil?

        authorize item, :destroy?
        item.destroy!
        head :no_content
      end

      private

      def offer_param
        return if params[:offer_id].blank?

        require_api_feature!(:offers)
        Offer.find(params[:offer_id])
      end
    end
  end
end
