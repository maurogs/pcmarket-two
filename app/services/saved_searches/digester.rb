# frozen_string_literal: true

module SavedSearches
  # Builds at most one digest email per user from every due daily/weekly saved
  # search. Searches with no new matches still advance last_notified_at so the
  # next run does not rescan the same listings.
  class Digester
    MAX_MATCHES_PER_SEARCH = 50
    CANDIDATE_BATCH = 100

    def call
      evaluated = []
      entries_by_user = Hash.new { |hash, key| hash[key] = [] }

      due_searches.find_each do |search|
        matches = matches_for(search)
        evaluated << [ search, matches ]
        next if matches.empty?

        entries_by_user[search.user_id] << { saved_search: search, listings: matches }
      end

      deliver_digests(entries_by_user)
      mark_evaluated(evaluated)

      evaluated.sum { |(_, matches)| matches.size }
    end

    private

    def due_searches
      SavedSearch
        .where(email_alerts: true, frequency: %w[daily weekly])
        .where(
          "(frequency = 'daily' AND (last_notified_at IS NULL OR last_notified_at <= :day)) OR " \
          "(frequency = 'weekly' AND (last_notified_at IS NULL OR last_notified_at <= :week))",
          day: 1.day.ago, week: 1.week.ago
        )
        .includes(:category, user: :notification_preferences)
    end

    def matches_for(search)
      since = search.last_notified_at || search.created_at
      relation = Listing.visible
                        .where("listings.published_at > ?", since)
                        .includes(:category, :tags, :store)
      relation = relation.in_category(search.category) if search.category.present?
      relation = apply_price_range(relation, search)

      collect_matches(search, relation)
    end

    # Newest first, walking candidate windows until enough matches are found.
    def collect_matches(search, relation)
      matches = []
      offset = 0

      loop do
        batch = relation
                .order(published_at: :desc, id: :desc)
                .limit(CANDIDATE_BATCH)
                .offset(offset)
                .to_a
        break if batch.empty?

        batch.each do |listing|
          matches << listing if search.matches?(listing)
          break if matches.size >= MAX_MATCHES_PER_SEARCH
        end

        break if matches.size >= MAX_MATCHES_PER_SEARCH || batch.size < CANDIDATE_BATCH

        offset += batch.size
      end

      matches
    end

    def apply_price_range(relation, search)
      min = numeric_param(search.query_params["min_price"])
      max = numeric_param(search.query_params["max_price"])

      relation = relation.where(price_cents: (min * 100).round..) if min
      relation = relation.where(price_cents: ..(max * 100).round) if max
      relation
    end

    def deliver_digests(entries_by_user)
      preferences_cache = {}

      entries_by_user.each_value do |entries|
        user = entries.first[:saved_search].user
        next if user.blank?

        preferences = preferences_cache[user.id] ||= NotificationPreference.settings_for(user)
        next unless NotificationPreference.email?(
          user, "saved_search_match", preferences: preferences
        )

        AlertMailer.saved_search_digest(user, entries).deliver_later
      end
    end

    def mark_evaluated(evaluated)
      now = Time.current

      evaluated.each do |(search, matches)|
        updates = { last_notified_at: now }
        updates[:last_matched_listing_id] = matches.map(&:id).max if matches.any?
        search.update_columns(updates)
      end
    end

    def numeric_param(value)
      return nil if value.nil? || value.to_s.strip.empty?

      number = BigDecimal(value.to_s)
      number.finite? && number >= 0 ? number : nil
    rescue ArgumentError, TypeError
      nil
    end
  end
end
