# frozen_string_literal: true

module SavedSearches
  class MatchListingJob < ApplicationJob
    queue_as :default

    def perform(listing_id)
      listing = Listing.includes(:category, :tags, :store).find_by(id: listing_id)
      return if listing.blank?

      SavedSearches::Matcher.new(listing).call
    end
  end
end
