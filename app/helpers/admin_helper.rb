# frozen_string_literal: true

module AdminHelper
  # The sidebar keeps every future screen visible but only links the screens
  # that exist. Items without a path render as disabled "coming soon" rows.
  def admin_nav_items
    [
      { key: "dashboard", path: admin_root_path },
      { key: "moderation", path: admin_listing_reviews_path },
      { key: "listings", path: admin_listings_path },
      { key: "users", path: admin_users_path },
      { key: "stores", path: admin_stores_path },
      { key: "orders", path: admin_orders_path },
      { key: "payouts", path: admin_payouts_path },
      { key: "categories" },
      { key: "filters" },
      { key: "tags" },
      { key: "countries" },
      { key: "settings" },
      { key: "feature_flags", path: "/admin/flipper" },
      { key: "legal" },
      { key: "reports", path: admin_reports_path },
      { key: "audit_log", path: admin_audit_logs_path }
    ]
  end

  def admin_nav_item_active?(item)
    path = item[:path]
    return false if path.blank?

    return true if current_page?(path)
    return false if item[:key] == "dashboard"

    request.path.start_with?("#{path}/")
  rescue ActionController::UrlGenerationError
    false
  end

  def admin_nav_item_classes(active)
    base = "flex items-center justify-between gap-2 rounded-xl px-3 py-2 text-sm font-medium transition"
    return "#{base} bg-primary-600 text-white" if active

    "#{base} text-content hover:bg-surface-muted"
  end

  def admin_kpi_label(key)
    t("admin.dashboard.kpis.#{key}")
  end

  def admin_kpi_value(key, value)
    key.to_s.end_with?("_cents") ? money(value, currency: "EUR") : value
  end

  def admin_filters_active?(filters)
    filters.except(:q).values.any? { |value| value.is_a?(FalseClass) || value.present? }
  end

  def admin_moderation_reason_label(code)
    t("admin.moderation.reasons.#{code}")
  end

  def admin_moderation_action_label(action)
    t("admin.moderation.actions.#{action}")
  end

  def admin_seller_kind_label(kind)
    t("admin.moderation.filters.seller_kinds.#{kind}")
  end

  # Sortable table headers. The current direction is reversed on click and the
  # page resets to the first one.
  def admin_sort_link(label, key, query:, path:)
    active = query.sort == key
    next_direction = active && query.direction == "asc" ? "desc" : "asc"
    extra = request.query_parameters.merge("sort" => key, "direction" => next_direction).except("page")
    arrow = if active
      query.direction == "asc" ? "↑" : "↓"
    else
      "↕"
    end

    link_to send(path, extra),
            class: "inline-flex items-center gap-1 font-semibold uppercase tracking-widest transition hover:text-content",
            aria: { sort: (active ? (query.direction == "asc" ? "ascending" : "descending") : "none") } do
      safe_join([ label, content_tag(:span, arrow, aria: { hidden: "true" }, class: "text-[10px] opacity-60") ])
    end
  end

  # Inline SVG sparkline for the dashboard; no JavaScript or chart library.
  def admin_sparkline(series)
    values = series.map { |point| point[:count].to_i }
    max = [ values.max.to_i, 1 ].max
    width = 300
    height = 60
    step = values.size > 1 ? width.to_f / (values.size - 1) : width
    points = values.each_with_index.map do |value, index|
      x = (index * step).round(2)
      y = (height - (value.to_f / max * (height - 6)) - 3).round(2)
      "#{x},#{y}"
    end.join(" ")

    content_tag(:svg, viewBox: "0 0 #{width} #{height}", class: "h-16 w-full", role: "img",
                     preserveAspectRatio: "none") do
      safe_join([
        content_tag(:title, t("admin.dashboard.sparkline.title")),
        content_tag(:polyline, nil, points: points, fill: "none", stroke: "currentColor",
                                   "stroke-width": "2", "stroke-linejoin": "round",
                                   "stroke-linecap": "round")
      ])
    end
  end

  def admin_listing_status_label(status)
    t("admin.listings.statuses.#{status}")
  end

  def admin_user_role_label(role)
    t("admin.users.roles.#{role}")
  end

  def admin_user_status_label(status)
    t("admin.users.statuses.#{status}")
  end

  def admin_store_kind_label(kind)
    t("admin.stores.kinds.#{kind}")
  end

  def admin_store_status_label(status)
    t("admin.stores.statuses.#{status}")
  end

  def admin_payout_status_label(status)
    t("admin.payouts.statuses.#{status}")
  end

  def admin_audit_action_label(action)
    t("admin.audit_logs.actions.#{action}", default: action)
  end

  def admin_auditable_label(record)
    return t("admin.audit_logs.deleted_item") if record.blank?

    case record
    when Listing then record.title.presence || "##{record.id}"
    when User then record.display_name
    when Store then record.name
    when Order then record.number
    when Review then t("admin.audit_logs.review", id: record.id)
    when Payout then t("admin.audit_logs.payout", id: record.id)
    else "##{record.id}"
    end
  end

  def admin_status_badge_class(status)
    case status.to_s
    when "published", "active", "completed", "paid", "visible" then "border-success/40 bg-success-soft text-success"
    when "pending_review", "pending_payment", "pending" then "border-warning/40 bg-warning-soft text-warning"
    when "draft", "archived", "cancelled", "suspended", "hidden" then "border-border bg-surface-muted text-muted"
    when "rejected", "banned", "deleted", "disputed", "failed" then "border-danger/40 bg-danger-soft text-danger"
    else "border-primary-200 bg-primary-50 text-primary-700 dark:border-primary-800 dark:bg-primary-900/30 dark:text-primary-200"
    end
  end
end
