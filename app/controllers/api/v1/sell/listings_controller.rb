# frozen_string_literal: true

module Api
  module V1
    module Sell
      class ListingsController < AuthenticatedController
        before_action :ensure_store
        before_action :set_listing, only: %i[update destroy]

        def index
          collection = ::Sell::ListingCollection.new(
            user: current_user, params: request.query_parameters
          ).call
          pagy = collection.pagy

          set_pagination_headers(pagy)
          render_collection(
            collection.listings, ListingDetailSerializer,
            meta: collection_meta(pagy, extra: {
              tab: collection.tab,
              counts: collection.counts,
              query: collection.query
            })
          )
        end

        def create
          listing = ::Sell::BuildListing.new(user: current_user).call
          authorize listing
          step = normalized_step(params[:step] || "category")

          unless save_step(listing, step)
            raise Api::V1::Error.validation_failed(
              details: validation_details(listing)
            )
          end

          render_resource(listing.reload, ListingDetailSerializer, status: :created)
        end

        def update
          authorize @listing
          step = normalized_step(params[:step])

          unless save_step(@listing, step)
            raise Api::V1::Error.validation_failed(
              details: validation_details(@listing)
            )
          end

          render_resource(@listing.reload, ListingDetailSerializer)
        end

        def destroy
          authorize @listing

          unless @listing.draft?
            raise Api::V1::Error.conflict(message_key: "api.sell.archive_instead")
          end

          @listing.destroy!
          head :no_content
        end

        private

        def ensure_store
          return if current_user.store.present?

          raise Api::V1::Error.forbidden(message_key: "sell.errors.store_required")
        end

        def set_listing
          @listing = Listing.friendly.find(params[:id])
        end

        def save_step(listing, step)
          ::Listings::SaveStep.new(
            listing: listing,
            step: step,
            attributes: listing_params,
            images: params.dig(:listing, :images),
            photo_signed_ids: params.dig(:listing, :photo_signed_ids) || params[:photo_signed_ids],
            photo_order: params.dig(:listing, :photo_order) || params[:photo_order],
            remove_photo_ids: params.dig(:listing, :remove_photo_ids) || params[:remove_photo_ids]
          ).call
        end

        def listing_params
          params.fetch(:listing, ActionController::Parameters.new).permit(
            :category_id, :title, :description, :condition,
            :price, :compare_at_price, :quantity, :allow_offers,
            :shipping_mode, :shipping_price, :free_shipping, :handling_days,
            :region_id, :city, :postal_code,
            specs: {}, seller_tag_ids: []
          )
        end

        def normalized_step(value)
          step = value.to_s
          Listing::WIZARD_STEPS.include?(step) ? step : Listing::WIZARD_STEPS.first
        end

        def validation_details(record)
          record.errors.to_hash(true).transform_keys(&:to_s)
        end
      end
    end
  end
end
