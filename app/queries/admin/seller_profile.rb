# frozen_string_literal: true

module Admin
  # Seller-level facts shown in the moderation queue. Counting a seller's past
  # rejections is batched for the index so rendering a page costs one query.
  class SellerProfile
    attr_reader :listing

    def initialize(listing:, rejection_count: nil)
      @listing = listing
      @rejection_count = rejection_count
    end

    def seller
      listing.seller
    end

    def store
      listing.store
    end

    def account_age_days
      return 0 if seller&.created_at.blank?

      ((Time.current - seller.created_at) / 1.day).floor
    end

    def previous_rejections_count
      @rejection_count ||= self.class.rejection_counts([ seller&.id ])[seller&.id] || 0
    end

    def verified?
      store.present? && store.verified?
    end

    def self.rejection_counts(user_ids)
      ids = Array(user_ids).compact.uniq
      return {} if ids.empty?

      ListingModeration
        .where(action: :rejected)
        .joins(:listing)
        .where(listings: { user_id: ids })
        .group("listings.user_id")
        .count
    end
  end
end
