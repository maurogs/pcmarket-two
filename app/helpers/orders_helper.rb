# frozen_string_literal: true

module OrdersHelper
  def order_status_label(status)
    t("orders.statuses.#{status}")
  end

  def order_status_badge_class(status)
    case status.to_s
    when "pending_payment" then "border-warning/40 bg-warning-soft text-warning"
    when "paid", "shipped", "delivered" then "border-primary-200 bg-primary-50 text-primary-700 dark:border-primary-800 dark:bg-primary-900/30 dark:text-primary-200"
    when "completed" then "border-success/40 bg-success-soft text-success"
    when "cancelled", "refunded" then "border-border bg-surface-muted text-muted"
    when "disputed" then "border-danger/40 bg-danger-soft text-danger"
    else "border-border bg-surface-muted text-muted"
    end
  end

  def order_fulfilment_label(order)
    t("orders.fulfilments.#{order.fulfilment}")
  end

  def carrier_options
    Order::CARRIERS.map { |carrier| [ t("orders.carriers.#{carrier}"), carrier ] }
  end

  def order_timeline(order)
    order.events.chronological.map do |event|
      { label: t("orders.events.#{event.event}"), at: event.created_at, actor: event.actor }
    end
  end

  def order_address_lines(order)
    address = order.checkout.shipping_address.with_indifferent_access
    [
      address[:full_name],
      address[:line1],
      address[:line2],
      [ address[:postal_code], address[:city] ].compact_blank.join(" "),
      address[:province],
      address[:country_code]
    ].compact_blank
  end

  def can_manage_sale?(order)
    Sell::OrderPolicy.new(current_user, order).cancel?
  end

  def can_ship?(order)
    Sell::OrderPolicy.new(current_user, order).ship?
  end
end
