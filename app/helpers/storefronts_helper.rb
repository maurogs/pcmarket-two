# frozen_string_literal: true

module StorefrontsHelper
  def storefront_tab_path(store, tab, extra = {})
    storefront_path(store, extra.merge(tab: tab))
  end

  def storefront_tab_classes(active)
    base = "inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold transition"
    active ? "#{base} bg-primary-600 text-white" : "#{base} text-muted hover:bg-surface-muted hover:text-content"
  end

  def storefront_location(store)
    store.province.presence || store.region&.name.presence
  end

  def storefront_review_sort_options
    [
      [ t("storefronts.reviews.sort.newest"), "newest" ],
      [ t("storefronts.reviews.sort.highest"), "highest" ],
      [ t("storefronts.reviews.sort.lowest"), "lowest" ]
    ]
  end

  def review_distribution_width(count, total)
    return 0 if total.to_i.zero?

    (count.to_i * 100.0 / total.to_i).round
  end

  def storefront_review_count(store)
    t("storefronts.reviews.count", count: store.ratings_count)
  end
end
