# frozen_string_literal: true

module Favourites
  # Notifies every user who favourited a listing that its price dropped. In-app
  # rows always honour the user's in-app preference; the email is only enqueued
  # when the listing is still publicly visible and email alerts are enabled.
  class PriceDrop
    def initialize(listing, previous_cents: nil, new_cents: nil)
      @listing = listing
      @previous_cents = previous_cents
      @new_cents = new_cents
    end

    def call
      return 0 if listing.blank?

      preferences_cache = {}
      notified = 0

      listing.favourites.includes(user: :notification_preferences).find_each do |favourite|
        user = favourite.user
        next if user.blank?

        preferences = preferences_cache[user.id] ||= NotificationPreference.settings_for(user)
        Notifications.record(
          recipient: user,
          kind: "price_drop",
          notifiable: listing,
          params: notification_params,
          preferences: preferences
        )

        if Notifications.deliver_email?(user, "price_drop", preferences: preferences) &&
           listing.publicly_visible?
          AlertMailer.price_drop(user, listing).deliver_later
        end

        notified += 1
      end

      notified
    end

    private

    attr_reader :listing, :previous_cents, :new_cents

    def notification_params
      {
        title: listing.title,
        price_cents: new_cents || listing.price_cents,
        previous_price_cents: previous_cents,
        currency: listing.currency,
        store_name: listing.store&.name
      }
    end
  end
end
