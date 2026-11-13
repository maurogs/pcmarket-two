# frozen_string_literal: true

require "test_helper"

class TrustStatsTest < ActiveSupport::TestCase
  test "only exposes figures that clear their minimum" do
    stats = TrustStats.new(listings_sold: 25, active_sellers: 9, average_rating: 4.4, ratings_count: 5)

    assert stats.show_listings_sold?
    assert_not stats.show_active_sellers?
    assert stats.show_rating?
    assert stats.any?
  end

  test "hides the rating without enough reviews" do
    stats = TrustStats.new(listings_sold: 0, active_sellers: 0, average_rating: 5, ratings_count: 4)

    assert_not stats.show_rating?
    assert_not stats.any?
  end

  test "caches the aggregate figures for an hour" do
    store = ActiveSupport::Cache::MemoryStore.new

    with_cache(store) do
      first = TrustStats.call
      second = TrustStats.call

      assert_equal first, second
      assert store.exist?(TrustStats::CACHE_KEY)
    end
  end
end
