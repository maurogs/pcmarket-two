# frozen_string_literal: true

require "test_helper"

class SellAnalyticsTest < ActiveSupport::TestCase
  setup do
    @store = stores(:confirmed_store)
    @buyer = users(:moderator)
    @listing_one = listings(:published_gpu)
    @listing_two = listings(:amd_gpu)
    ListingView.where(listing: [ @listing_one, @listing_two ]).delete_all
  end

  def create_order(status:, paid_at:, total_cents:, listing:, quantity:, unit_price_cents:)
    checkout = Checkout.create!(
      buyer: @buyer,
      email: @buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
    order = Order.create!(
      checkout: checkout,
      buyer: @buyer,
      store: @store,
      status: status,
      paid_at: paid_at,
      subtotal_cents: total_cents,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: total_cents,
      currency: "EUR"
    )
    order.items.create!(
      listing: listing,
      quantity: quantity,
      unit_price_cents: unit_price_cents,
      shipping_cents: 0,
      title: listing.title,
      seller_name: @store.name
    )
    order
  end

  test "computes KPIs and rankings from aggregate queries" do
    create_order(status: "paid", paid_at: 2.days.ago, total_cents: 10_000,
                 listing: @listing_one, quantity: 2, unit_price_cents: 5_000)
    create_order(status: "delivered", paid_at: 10.days.ago, total_cents: 5_000,
                 listing: @listing_two, quantity: 1, unit_price_cents: 5_000)

    ListingView.create!(listing: @listing_one, date: Date.current, views: 40)
    ListingView.create!(listing: @listing_two, date: Date.current, views: 10)
    Favourite.create!(user: users(:admin), listing: @listing_one)
    Follow.create!(follower: users(:admin), store: @store)

    analytics = with_cache(ActiveSupport::Cache::MemoryStore.new) do
      Sell::Analytics.new(store: @store, range: 30).call
    end

    assert_equal 15_000, analytics.revenue_cents
    assert_equal 2, analytics.orders_count
    assert_equal 3, analytics.units_sold
    assert_equal 7_500, analytics.average_order_cents
    assert_equal 50, analytics.views
    assert_in_delta 0.04, analytics.conversion_rate, 0.0001
    assert_equal 1, analytics.favourites_gained
    assert_equal 1, analytics.new_followers
    assert_equal 30, analytics.revenue_by_day.size
    assert_equal 15_000, analytics.revenue_by_day.sum { |point| point[:amount_cents] }

    assert_equal @listing_one.id, analytics.top_by_views.first[:listing].id
    assert_equal 40, analytics.top_by_views.first[:value]
    assert_equal @listing_one.id, analytics.top_by_revenue.first[:listing].id
    assert_equal 10_000, analytics.top_by_revenue.first[:value]

    assert_equal 1, analytics.pending[:orders_to_ship]
    assert_equal 1, analytics.pending[:rejected_listings]
  end

  test "finishes pending numbers and caches the result per range" do
    analytics = with_cache(ActiveSupport::Cache::MemoryStore.new) do
      first = Sell::Analytics.new(store: @store, range: 7).call
      ListingView.create!(listing: @listing_one, date: Date.current, views: 30)
      second = Sell::Analytics.new(store: @store, range: 7).call

      assert_equal 0, first.views
      assert_equal 0, second.views
      second
    end

    assert_equal 7, analytics.range
  end
end
