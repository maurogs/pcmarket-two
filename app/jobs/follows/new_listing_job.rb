# frozen_string_literal: true

module Follows
  class NewListingJob < ApplicationJob
    queue_as :default

    def perform(listing_id)
      listing = Listing.includes(:store).find_by(id: listing_id)
      return if listing.blank?

      Follows::NewListing.new(listing).call
    end
  end
end
