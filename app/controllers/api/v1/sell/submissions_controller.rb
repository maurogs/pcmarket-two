# frozen_string_literal: true

module Api
  module V1
    module Sell
      class SubmissionsController < AuthenticatedController
        def create
          listing = Listing.friendly.find(params[:listing_id])
          authorize listing, :update?

          unless ::Listings::Submit.new(listing: listing).call
            raise Api::V1::Error.validation_failed(
              details: listing.errors.to_hash(true).transform_keys(&:to_s)
            )
          end

          render_resource(listing.reload, ListingDetailSerializer)
        end
      end
    end
  end
end
