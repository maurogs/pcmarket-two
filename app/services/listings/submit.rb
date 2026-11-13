# frozen_string_literal: true

module Listings
  # Submits a completed draft for moderation. The AASM event decides whether it
  # goes to pending_review or straight to published (approval setting off).
  class Submit
    def initialize(listing:)
      @listing = listing
    end

    def call
      return false unless listing.valid?(:review)

      return false unless listing.submit!

      # TODO: enqueue the moderator notification once the notifications mailer
      # exists. The listing is already in pending_review at this point.
      true
    end

    private

    attr_reader :listing
  end
end
