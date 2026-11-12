# frozen_string_literal: true

module SellHelper
  def wizard_step_label(step)
    case step.to_s
    when "photos" then t("sell.steps.photos")
    when "details" then t("sell.steps.details")
    when "price" then t("sell.steps.price")
    when "review" then t("sell.steps.review")
    else t("sell.steps.category")
    end
  end

  def wizard_step_index(step)
    Listing::WIZARD_STEPS.index(step.to_s).to_i + 1
  end

  def wizard_step_percent(step)
    (wizard_step_index(step) * 100.0 / Listing::WIZARD_STEPS.length).round
  end

  def condition_title(condition)
    t("sell.details.conditions.#{condition}.title")
  end

  def condition_description(condition)
    t("sell.details.conditions.#{condition}.description")
  end

  def listing_spec_value(listing, definition)
    (listing.specs || {}).with_indifferent_access[definition.key]
  end

  def review_field_label(item)
    item[:label] || Listing.human_attribute_name(item[:attribute])
  end

  def sell_nav_items
    store = current_user&.store
    items = [
      { key: "analytics", path: sell_dashboard_path },
      { key: "listings", path: sell_listings_path },
      { key: "sales", path: sell_orders_path }
    ]
    if store.present?
      items << { key: "public_profile", path: storefront_path(store) }
      items << { key: "store_settings", path: edit_store_path }
      items << { key: "vacation", path: store_vacation_path }
      items << { key: "payouts", path: store_payment_path }
    end
    items
  end

  def sell_nav_item_classes(active)
    base = "flex items-center justify-between gap-2 rounded-xl px-3 py-2 text-sm font-medium transition"
    active ? "#{base} bg-primary-600 text-white" : "#{base} text-content hover:bg-surface-muted"
  end

  def analytics_percent(value)
    number_to_percentage(value.to_f * 100, precision: 1)
  end

  def analytics_range_label(range)
    case range.to_i
    when 7 then t("sell.dashboard.ranges.seven")
    when 90 then t("sell.dashboard.ranges.ninety")
    else t("sell.dashboard.ranges.thirty")
    end
  end

  def analytics_chart_max(series)
    [ series.map { |point| point[:amount_cents].to_i }.max.to_i, 1 ].max
  end
end
