# frozen_string_literal: true

module Api
  module V1
    module Sell
      class RepublicationsController < AuthenticatedController
        def create
          listing = Listing.friendly.find(params[:listing_id])
          authorize listing, :republish?
          listing.republish!
          render_resource(listing.reload, ListingDetailSerializer)
        end
      end
    end
  end
end
