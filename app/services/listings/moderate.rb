# frozen_string_literal: true

module Listings
  # Entry point for the admin moderation panel. Every decision is logged and
  # the seller is notified once the decision has been committed.
  class Moderate
    def initialize(listing:, moderator:, reason: nil)
      @listing = listing
      @moderator = moderator
      @reason = reason
    end

    def approve!
      perform(:approved) { listing.approve! }
    end

    def reject!
      if reason.blank?
        raise ArgumentError, I18n.t("listings.errors.rejection_reason_required")
      end

      perform(:rejected) { listing.reject!(reason) }
    end

    private

    attr_reader :listing, :moderator, :reason

    # The status check, the AASM transition and the moderation log share one
    # row lock. A second moderator therefore finds the listing already out of
    # pending_review and gets nil: no duplicate log and no second email.
    def perform(action)
      moderation = nil

      listing.with_lock do
        next unless listing.pending_review?
        next unless yield

        moderation = log(action)
      end

      return if moderation.nil?

      deliver_notification(action)
      moderation
    end

    def log(action)
      ListingModeration.create!(
        listing: listing,
        moderator: moderator,
        action: action,
        reason: reason
      )
    end

    def deliver_notification(action)
      mail = action == :approved ? ListingMailer.approved(listing) : ListingMailer.rejected(listing)
      mail.deliver_later

      Notifications.record(
        recipient: listing.seller,
        kind: "listing_#{action}",
        notifiable: listing,
        params: {
          title: listing.title,
          reason: action == :rejected ? listing.rejection_reason : nil
        }
      )
    end
  end
end
