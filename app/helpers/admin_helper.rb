# frozen_string_literal: true

module AdminHelper
  # The sidebar keeps every future screen visible but only links the screens
  # that exist. Items without a path render as disabled "coming soon" rows.
  def admin_nav_items
    [
      { key: "dashboard", path: admin_root_path },
      { key: "moderation", path: admin_listing_reviews_path },
      { key: "listings" },
      { key: "users" },
      { key: "stores" },
      { key: "orders" },
      { key: "categories" },
      { key: "filters" },
      { key: "tags" },
      { key: "countries" },
      { key: "settings" },
      { key: "feature_flags", path: "/admin/flipper" },
      { key: "legal" },
      { key: "reports" }
    ]
  end

  def admin_nav_item_active?(item)
    return false if item[:path].blank?

    current_page?(item[:path])
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

  def admin_moderation_reason_label(code)
    t("admin.moderation.reasons.#{code}")
  end

  def admin_moderation_action_label(action)
    t("admin.moderation.actions.#{action}")
  end

  def admin_seller_kind_label(kind)
    t("admin.moderation.filters.seller_kinds.#{kind}")
  end
end
