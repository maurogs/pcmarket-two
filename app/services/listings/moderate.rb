# frozen_string_literal: true

module Listings
  # Entry point for the admin moderation panel. Every decision is logged.
  class Moderate
    def initialize(listing:, moderator:, reason: nil)
      @listing = listing
      @moderator = moderator
      @reason = reason
    end

    def approve!
      ListingModeration.transaction do
        listing.approve!
        log(:approved)
      end
    end

    def reject!
      if reason.blank?
        raise ArgumentError, I18n.t("listings.errors.rejection_reason_required")
      end

      ListingModeration.transaction do
        listing.reject!(reason)
        log(:rejected)
      end
    end

    private

    attr_reader :listing, :moderator, :reason

    def log(action)
      ListingModeration.create!(
        listing: listing,
        moderator: moderator,
        action: action,
        reason: reason
      )
    end
  end
end
