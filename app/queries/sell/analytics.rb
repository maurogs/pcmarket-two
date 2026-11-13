# frozen_string_literal: true

module Sell
  # Computes the seller analytics screen from a handful of aggregate queries
  # and caches the result for ten minutes per store and range.
  class Analytics
    RANGES = [ 7, 30, 90 ].freeze
    DEFAULT_RANGE = 30
    CACHE_TTL = 10.minutes
    REVENUE_STATUSES = %w[paid shipped delivered completed].freeze

    Result = Struct.new(
      :range,
      :start_date,
      :end_date,
      :revenue_cents,
      :orders_count,
      :units_sold,
      :average_order_cents,
      :views,
      :conversion_rate,
      :favourites_gained,
      :new_followers,
      :revenue_by_day,
      :top_by_views,
      :top_by_revenue,
      :pending,
      keyword_init: true
    )

    def initialize(store:, range: DEFAULT_RANGE)
      @store = store
      @range = RANGES.include?(range.to_i) ? range.to_i : DEFAULT_RANGE
    end

    def call
      Result.new(**cached_payload)
    end

    private

    attr_reader :store, :range

    def cached_payload
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { payload }
    end

    def cache_key
      [ "sell/analytics", store.id, store.updated_at.to_i, range ]
    end

    def payload
      {
        range: range,
        start_date: start_date,
        end_date: end_date,
        revenue_cents: revenue_cents.to_i,
        orders_count: orders_count,
        units_sold: units_sold,
        average_order_cents: average_order_cents,
        views: views,
        conversion_rate: conversion_rate,
        favourites_gained: favourites_gained,
        new_followers: new_followers,
        revenue_by_day: revenue_by_day,
        top_by_views: top_by_views,
        top_by_revenue: top_by_revenue,
        pending: pending
      }
    end

    def start_date
      @start_date ||= (range - 1).days.ago.to_date
    end

    def end_date
      @end_date ||= Date.current
    end

    def period
      start_date.beginning_of_day..end_date.end_of_day
    end

    def orders
      @orders ||= store.orders.where(status: REVENUE_STATUSES).where(paid_at: period)
    end

    def order_stats
      @order_stats ||= orders.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COALESCE(SUM(total_cents), 0)")
      )
    end

    def orders_count
      order_stats.first.to_i
    end

    def revenue_cents
      order_stats.last.to_i
    end

    def units_sold
      @units_sold ||= OrderItem.where(order_id: orders.select(:id)).sum(:quantity)
    end

    def average_order_cents
      return 0 if orders_count.zero?

      (revenue_cents.to_f / orders_count).round
    end

    def views
      @views ||= ListingView.joins(:listing)
                            .where(listings: { store_id: store.id })
                            .where(date: start_date..end_date)
                            .sum(:views)
    end

    def conversion_rate
      return 0.0 if views.zero?

      (orders_count.to_f / views).round(4)
    end

    def favourites_gained
      @favourites_gained ||= Favourite.joins(:listing)
                                      .where(listings: { store_id: store.id })
                                      .where(created_at: period)
                                      .count
    end

    def new_followers
      @new_followers ||= Follow.where(store_id: store.id).where(created_at: period).count
    end

    def revenue_by_day
      @revenue_by_day ||= begin
        totals = orders.group(Arel.sql("DATE(orders.paid_at)")).sum(:total_cents)
        (start_date..end_date).map do |date|
          { date: date, amount_cents: totals[date].to_i }
        end
      end
    end

    def top_by_views
      @top_by_views ||= begin
        totals = ListingView.joins(:listing)
                            .where(listings: { store_id: store.id })
                            .where(date: start_date..end_date)
                            .group("listing_views.listing_id")
                            .sum(:views)
        ranked = totals.sort_by { |_listing_id, count| -count }.first(5)
        listings = store.listings.where(id: ranked.map(&:first)).index_by(&:id)
        ranked.filter_map do |listing_id, count|
          listing = listings[listing_id]
          next if listing.nil?

          { listing: listing, value: count }
        end
      end
    end

    def top_by_revenue
      @top_by_revenue ||= begin
        totals = OrderItem.joins(:order)
                          .where(orders: { id: orders.select(:id) })
                          .group("order_items.listing_id")
                          .sum(Arel.sql("order_items.unit_price_cents * order_items.quantity"))
        ranked = totals.sort_by { |_listing_id, amount| -amount }.first(5)
        listings = store.listings.where(id: ranked.map(&:first)).index_by(&:id)
        ranked.filter_map do |listing_id, amount|
          listing = listings[listing_id]
          next if listing.nil?

          { listing: listing, value: amount }
        end
      end
    end

    def pending
      {
        orders_to_ship: store.orders.where(status: "paid").count,
        offers_to_answer: Offer.pending.joins(:listing)
                                .where(listings: { store_id: store.id }).count,
        unread_messages: Conversation.where(store_id: store.id).sum(:seller_unread_count),
        rejected_listings: store.listings.where(status: "rejected").count
      }
    end
  end
end
