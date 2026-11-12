# frozen_string_literal: true

module Api
  module V1
    module Sell
      class ArchivalsController < AuthenticatedController
        def create
          listing = Listing.friendly.find(params[:listing_id])
          authorize listing, :update?
          listing.archive!
          render_resource(listing.reload, ListingDetailSerializer)
        end
      end
    end
  end
end
