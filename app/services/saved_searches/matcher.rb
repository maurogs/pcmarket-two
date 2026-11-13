# frozen_string_literal: true

module SavedSearches
  # Finds saved searches that match a newly published listing. Category and
  # price are filtered in SQL; the remaining criteria are evaluated in Ruby on
  # the small candidate set.
  class Matcher
    def initialize(listing)
      @listing = listing
      @preferences_cache = {}
    end

    def call
      return 0 unless listing&.persisted? && listing.publicly_visible?

      matched = 0

      candidate_searches.find_each do |search|
        next unless search.matches?(listing)

        process(search)
        matched += 1
      end

      matched
    end

    private

    attr_reader :listing

    def candidate_searches
      ids = candidate_category_ids
      scope = SavedSearch.where(category_id: nil)
      scope = scope.or(SavedSearch.where(category_id: ids)) if ids.any?
      price_prefilter(scope.includes(:category, user: :notification_preferences))
    end

    # Saved searches are stored on a category and must match the listing's
    # whole ancestor chain (a search on "GPUs" matches listings in "NVIDIA").
    def candidate_category_ids
      return [] if listing.category_id.blank?

      Category.ancestor_ids_for(listing.category_id) + [ listing.category_id ]
    end

    def price_prefilter(relation)
      return relation if listing.price_cents.nil?

      price = listing.price_cents.to_i
      relation.where(
        <<~SQL.squish,
          (CASE
            WHEN (query_params->>'min_price') ~ '^[0-9]+([.][0-9]+){0,1}$'
            THEN ((query_params->>'min_price')::numeric * 100)
          END) IS NULL
          OR
          (CASE
            WHEN (query_params->>'min_price') ~ '^[0-9]+([.][0-9]+){0,1}$'
            THEN ((query_params->>'min_price')::numeric * 100)
          END) <= ?
        SQL
        price
      ).where(
        <<~SQL.squish,
          (CASE
            WHEN (query_params->>'max_price') ~ '^[0-9]+([.][0-9]+){0,1}$'
            THEN ((query_params->>'max_price')::numeric * 100)
          END) IS NULL
          OR
          (CASE
            WHEN (query_params->>'max_price') ~ '^[0-9]+([.][0-9]+){0,1}$'
            THEN ((query_params->>'max_price')::numeric * 100)
          END) >= ?
        SQL
        price
      )
    end

    def process(search)
      Notifications.record(
        recipient: search.user,
        kind: "saved_search_match",
        notifiable: listing,
        params: {
          name: search.name,
          title: listing.title,
          listing_id: listing.id
        },
        preferences: preferences_for(search.user)
      )

      if search.instant? && search.email_alerts? &&
         Notifications.deliver_email?(
           search.user, "saved_search_match", preferences: preferences_for(search.user)
         )
        AlertMailer.saved_search_match(search, listing).deliver_later
        mark_instant_match(search)
      else
        search.update_columns(last_matched_listing_id: listing.id)
      end
    end

    def mark_instant_match(search)
      search.update_columns(
        last_notified_at: Time.current,
        last_matched_listing_id: listing.id
      )
    end

    def preferences_for(user)
      @preferences_cache[user.id] ||= NotificationPreference.settings_for(user)
    end
  end
end
