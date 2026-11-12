# frozen_string_literal: true

module Admin
  # A small set of cheap COUNTs for the dashboard. The whole result is cached
  # for a minute because the numbers do not need to be exact to the second.
  class DashboardStats
    CACHE_KEY = "admin/dashboard/stats"
    CACHE_TTL = 60.seconds
    SERIES_DAYS = 30

    KPI_KEYS = %i[
      pending_listings
      published_today
      published_last_7_days
      new_users_today
      new_users_last_7_days
      active_stores
      published_listings
      open_reports
      gmv_7d_cents
      gmv_30d_cents
      orders_7d
      commission_30d_cents
      open_disputes
      failed_payouts
    ].freeze

    Stats = Struct.new(*KPI_KEYS, :orders_series, keyword_init: true)

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
        open_reports: Report.unresolved.count,
        gmv_7d_cents: gmv_since(7.days.ago),
        gmv_30d_cents: gmv_since(30.days.ago),
        orders_7d: Order.where(created_at: 7.days.ago..).count,
        commission_30d_cents: Order.where(paid_at: 30.days.ago..).sum(:commission_cents),
        open_disputes: Order.where(status: "disputed").count,
        failed_payouts: Payout.where(status: "failed").count,
        orders_series: orders_series
      )
    end

    private

    def published_since(time)
      Listing.published.where(published_at: time..)
    end

    def gmv_since(time)
      Order.where(paid_at: time..).sum(:total_cents)
    end

    # One grouped query over the last 30 days, zero-filled for the sparkline.
    def orders_series
      counts = Order.where(created_at: SERIES_DAYS.days.ago.beginning_of_day..)
                    .group(Arel.sql("DATE(created_at)")).count
      (0...SERIES_DAYS).map do |offset|
        date = (SERIES_DAYS - 1 - offset).days.ago.to_date
        { date: date, count: counts[date] || 0 }
      end
    end
  end
end
