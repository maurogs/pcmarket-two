# frozen_string_literal: true

# Estimates when an order is dispatched and delivered. Both the handling time
# and the 2-4 day carrier window are counted in business days, skipping
# Saturdays and Sundays. Deliveries are never promised on a single day, so the
# upper bound is exposed as a range.
class DeliveryEstimate
  MIN_DELIVERY_BUSINESS_DAYS = 2
  MAX_DELIVERY_BUSINESS_DAYS = 4

  attr_reader :handling_days, :order_date

  def initialize(handling_days:, order_date: Date.current)
    @handling_days = handling_days.to_i.clamp(0, 30)
    @order_date = order_date.respond_to?(:to_date) ? order_date.to_date : order_date
  end

  def ships_on
    start = order_date
    start += 1 until self.class.business_day?(start)
    self.class.add_business_days(start, handling_days)
  end

  def delivered_from
    self.class.add_business_days(ships_on, MIN_DELIVERY_BUSINESS_DAYS)
  end

  def delivered_to
    self.class.add_business_days(ships_on, MAX_DELIVERY_BUSINESS_DAYS)
  end

  def self.business_day?(date)
    !date.saturday? && !date.sunday?
  end

  def self.add_business_days(date, days)
    result = date
    remaining = days

    while remaining.positive?
      result += 1
      remaining -= 1 if business_day?(result)
    end

    result
  end
end
