# frozen_string_literal: true

module Admin
  # A small set of cheap COUNTs for the dashboard. The whole result is cached
  # for a minute because the numbers do not need to be exact to the second.
  class DashboardStats
    CACHE_KEY = "admin/dashboard/stats"
    CACHE_TTL = 60.seconds

    KPI_KEYS = %i[
      pending_listings
      published_today
      published_last_7_days
      new_users_today
      new_users_last_7_days
      active_stores
      published_listings
      open_reports
    ].freeze

    Stats = Struct.new(*KPI_KEYS, keyword_init: true)

    def self.call
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { new.call }
    end

    def call
      Stats.new(
        pending_listings: Listing.where(status: "pending_review").count,
        published_today: published_since(Time.current.beginning_of_day).count,
        published_last_7_days: published_since(7.days.ago).count,
        new_users_today: User.where(created_at: Time.current.beginning_of_day..).count,
        new_users_last_7_days: User.where(created_at: 7.days.ago..).count,
        active_stores: Store.active.count,
        published_listings: Listing.published.count,
        open_reports: Report.unresolved.count
      )
    end

    private

    def published_since(time)
      Listing.published.where(published_at: time..)
    end
  end
end
