# frozen_string_literal: true

module Api
  module V1
    class AnalyticsSerializer < BaseSerializer
      attributes :range, :start_date, :end_date, :revenue_cents, :orders_count,
                 :units_sold, :average_order_cents, :views, :conversion_rate,
                 :favourites_gained, :new_followers, :pending

      attribute :revenue_by_day do |analytics|
        analytics.revenue_by_day.map do |entry|
          { date: entry[:date].iso8601, amount_cents: entry[:amount_cents] }
        end
      end

      attribute :top_by_views do |analytics|
        analytics.top_by_views.map do |entry|
          { listing_id: entry[:listing].id, title: entry[:listing].title,
            value: entry[:value] }
        end
      end

      attribute :top_by_revenue do |analytics|
        analytics.top_by_revenue.map do |entry|
          { listing_id: entry[:listing].id, title: entry[:listing].title,
            value: entry[:value] }
        end
      end
    end
  end
end
