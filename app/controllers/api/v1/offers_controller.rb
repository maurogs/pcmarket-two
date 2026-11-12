# frozen_string_literal: true

module Api
  module V1
    class OffersController < AuthenticatedController
      before_action :ensure_offers_enabled

      def create
        listing = Listing.friendly.find(params[:listing_id])
        offer = Offer.new(listing: listing, buyer: current_user)
        authorize offer

        result = Offers::Create.new(
          listing: listing,
          buyer: current_user,
          amount_cents: Offer.cents_from_amount(params[:amount]),
          message: params[:message]
        ).call

        unless result.success?
          raise Api::V1::Error.validation_failed(details: { base: result.errors })
        end

        render_resource(result.offer, OfferSerializer, status: :created,
                        options: { params: { user: current_user } })
      end

      def update
        offer = Offer.find(params[:id])
        authorize offer

        result = Offers::Respond.new(
          offer: offer,
          actor: current_user,
          decision: params[:decision],
          amount_cents: Offer.cents_from_amount(params[:amount]),
          message: params[:message]
        ).call

        unless result.success?
          raise Api::V1::Error.validation_failed(details: { base: result.errors })
        end

        render_resource(result.offer.reload, OfferSerializer,
                        options: { params: { user: current_user } })
      end

      private

      def ensure_offers_enabled
        require_api_feature!(:offers)
      end
    end
  end
end
