# frozen_string_literal: true

module Favourites
  class PriceDropJob < ApplicationJob
    queue_as :default

    def perform(listing_id, previous_cents = nil, new_cents = nil)
      listing = Listing.find_by(id: listing_id)
      return if listing.blank?

      Favourites::PriceDrop.new(
        listing, previous_cents: previous_cents, new_cents: new_cents
      ).call
    end
  end
end
