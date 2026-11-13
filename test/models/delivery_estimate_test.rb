# frozen_string_literal: true

require "test_helper"

class DeliveryEstimateTest < ActiveSupport::TestCase
  test "ships after the handling days in business days" do
    estimate = DeliveryEstimate.new(handling_days: 3, order_date: Date.new(2026, 11, 9)) # Monday

    assert_equal Date.new(2026, 11, 12), estimate.ships_on # Thursday
    assert_equal Date.new(2026, 11, 16), estimate.delivered_from # Monday
    assert_equal Date.new(2026, 11, 18), estimate.delivered_to # Wednesday
  end

  test "skips weekends when handling" do
    estimate = DeliveryEstimate.new(handling_days: 1, order_date: Date.new(2026, 11, 13)) # Friday

    assert_equal Date.new(2026, 11, 16), estimate.ships_on # Monday
    assert_equal Date.new(2026, 11, 18), estimate.delivered_from # Wednesday
    assert_equal Date.new(2026, 11, 20), estimate.delivered_to # Friday
  end

  test "skips weekends for the delivery window" do
    estimate = DeliveryEstimate.new(handling_days: 2, order_date: Date.new(2026, 11, 12)) # Thursday

    assert_equal Date.new(2026, 11, 16), estimate.ships_on # Monday
    assert_equal Date.new(2026, 11, 18), estimate.delivered_from
    assert_equal Date.new(2026, 11, 20), estimate.delivered_to
  end

  test "handles zero handling days" do
    estimate = DeliveryEstimate.new(handling_days: 0, order_date: Date.new(2026, 11, 10))

    assert_equal Date.new(2026, 11, 10), estimate.ships_on
    assert_equal Date.new(2026, 11, 12), estimate.delivered_from
    assert_equal Date.new(2026, 11, 16), estimate.delivered_to
  end

  test "starts on the next business day when the order is placed on a weekend" do
    estimate = DeliveryEstimate.new(handling_days: 0, order_date: Date.new(2026, 11, 14))

    assert_equal Date.new(2026, 11, 16), estimate.ships_on
  end

  test "clamps negative handling days" do
    estimate = DeliveryEstimate.new(handling_days: -5, order_date: Date.new(2026, 11, 10))

    assert_equal 0, estimate.handling_days
    assert_equal Date.new(2026, 11, 10), estimate.ships_on
  end

  test "business day predicate excludes weekends only" do
    assert DeliveryEstimate.business_day?(Date.new(2026, 11, 13))
    assert_not DeliveryEstimate.business_day?(Date.new(2026, 11, 14))
    assert_not DeliveryEstimate.business_day?(Date.new(2026, 11, 15))
  end
end
