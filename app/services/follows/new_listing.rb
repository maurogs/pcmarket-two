# frozen_string_literal: true

module Follows
  # Notifies followers when a store publishes a listing. In-app notifications
  # are immediate; email digests are throttled to one per follow every 24 hours
  # so a seller publishing a whole batch only produces one email.
  class NewListing
    DIGEST_WINDOW = 24.hours
    MAX_DIGEST_LISTINGS = 20

    def initialize(listing)
      @listing = listing
    end

    def call
      return 0 unless listing&.publicly_visible?

      store = listing.store
      return 0 if store.blank?

      @digest_listings = nil
      preferences_cache = {}
      notified = 0

      store.follows.includes(follower: :notification_preferences).find_each do |follow|
        follower = follow.follower
        next if follower.blank?
        next if follower.id == store.user_id

        preferences = preferences_cache[follower.id] ||= NotificationPreference.settings_for(follower)
        Notifications.record(
          recipient: follower,
          kind: "followed_store_new_listing",
          notifiable: listing,
          params: notification_params,
          preferences: preferences
        )
        maybe_deliver_digest(follow, follower, store, preferences)
        notified += 1
      end

      notified
    end

    private

    attr_reader :listing

    def notification_params
      {
        store_name: listing.store.name,
        title: listing.title,
        listing_id: listing.id
      }
    end

    def maybe_deliver_digest(follow, follower, store, preferences)
      return unless Notifications.deliver_email?(
        follower, "followed_store_new_listing", preferences: preferences
      )

      follow.with_lock do
        next if follow.last_notified_at.present? &&
                follow.last_notified_at > DIGEST_WINDOW.ago

        AlertMailer.followed_store_new_listing(
          follower, store, digest_listings(store)
        ).deliver_later
        follow.update_column(:last_notified_at, Time.current)
      end
    end

    # The current listing is always included even when it fell outside the
    # 24-hour window (for example after a delayed job retry). Memoised because
    # every follower of the store receives the same digest payload.
    def digest_listings(store)
      @digest_listings ||= begin
        recent = store.listings
                      .visible
                      .where("published_at >= ?", DIGEST_WINDOW.ago)
                      .order(published_at: :desc, id: :desc)
                      .limit(MAX_DIGEST_LISTINGS)
                      .to_a

        recent.unshift(listing) unless recent.any? { |candidate| candidate.id == listing.id }
        recent.first(MAX_DIGEST_LISTINGS)
      end
    end
  end
end
