# frozen_string_literal: true

module ListingsHelper
  ATTRIBUTE_GROUPS = {
    "cpu" => "listings.attribute_groups.cpu",
    "general" => "listings.attribute_groups.general",
    "gpu" => "listings.attribute_groups.gpu",
    "lighting" => "listings.attribute_groups.lighting",
    "memory" => "listings.attribute_groups.memory",
    "motherboard" => "listings.attribute_groups.motherboard",
    "power" => "listings.attribute_groups.power",
    "storage" => "listings.attribute_groups.storage"
  }.freeze

  def condition_label(condition)
    t("listings.conditions.#{condition}")
  end

  def sort_options
    [
      [ t("listings.sort.best_match"), "best_match" ],
      [ t("listings.sort.newest"), "newest" ],
      [ t("listings.sort.price_asc"), "price_asc" ],
      [ t("listings.sort.price_desc"), "price_desc" ],
      [ t("listings.sort.popular"), "popular" ]
    ]
  end

  def filtered_path(remove_params)
    query = remove_params.to_query
    query.present? ? "#{request.path}?#{query}" : request.path
  end

  def browse_categories_path
    root = navigation_tree.first&.first
    root ? category_path(root) : root_path
  end

  def shipping_mode_label(mode)
    t("listings.shipping_modes.#{mode}")
  end

  def status_label(listing)
    t("listings.statuses.#{listing.status}")
  end

  STATUS_BADGE_CLASSES = {
    "draft" => "border-border bg-surface-muted text-muted",
    "pending_review" => "border-warning/40 bg-warning-soft text-warning",
    "published" => "border-success/40 bg-success-soft text-success",
    "reserved" => "border-primary-200 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/40 dark:text-primary-200",
    "rejected" => "border-danger/40 bg-danger-soft text-danger",
    "sold" => "border-content/20 bg-surface-muted text-content",
    "archived" => "border-border bg-surface-muted text-muted"
  }.freeze
  DEFAULT_STATUS_BADGE_CLASS = "border-border bg-surface-muted text-muted"

  def status_badge_class(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, DEFAULT_STATUS_BADGE_CLASS)
  end

  def attribute_group_label(group)
    key = ATTRIBUTE_GROUPS[group.to_s]
    key ? t(key) : group.to_s.humanize
  end

  def category_breadcrumbs(category)
    trail = [ [ t("nav.home"), root_path ] ]
    category.breadcrumb.each { |node| trail << [ node.name, category_path(node) ] }
    trail
  end

  def listing_breadcrumbs(listing)
    trail = [ [ t("nav.home"), root_path ] ]
    listing.category.breadcrumb.each { |node| trail << [ node.name, category_path(node) ] }
    trail << [ listing.title, listing_path(listing) ]
    trail
  end

  def search_breadcrumbs
    [ [ t("nav.home"), root_path ], [ t("listings.index.title"), search_path ] ]
  end

  def subcategory_chips(category)
    tree = Category.active_tree
    children = tree.select { |child| child.parent_id == category.id }
    if children.empty? && category.parent_id
      parent = tree.find { |candidate| candidate.id == category.parent_id } || category
      children = tree.select { |child| child.parent_id == parent.id }
      all_label = all_category_label(parent)
      all_path = category_path(parent)
    else
      all_label = all_category_label(category)
      all_path = category_path(category)
    end

    [
      { label: all_label, path: all_path, current: false },
      *children.map { |child| { label: child.name, path: category_path(child), current: child == category } }
    ]
  end

  def attribute_definitions_for(category)
    if defined?(@search) && @search
      preloaded = @search.attribute_definitions_by_category[category.id]
      return preloaded if preloaded
    end

    @attribute_definitions_cache ||= {}
    @attribute_definitions_cache[category.id] ||= category.effective_attribute_definitions
  end

  # Up to `limit` attributes flagged with show_on_card, with their values
  # resolved to human labels/units.
  def card_specs(listing, limit: 4)
    attribute_definitions_for(listing.category)
      .select(&:show_on_card?)
      .filter_map do |definition|
        raw = spec_value(listing, definition)
        next if raw.blank?

        { label: definition.name, value: spec_display_value(definition, raw) }
      end
      .first(limit)
  end

  def specification_groups(listing)
    rows = attribute_definitions_for(listing.category).filter_map do |definition|
      raw = spec_value(listing, definition)
      next if raw.blank?

      { definition: definition, value: spec_display_value(definition, raw) }
    end

    rows.group_by { |row| attribute_group_label(row[:definition].group) }
  end

  def spec_display_value(definition, raw)
    values = Array(raw).map(&:to_s).reject(&:empty?)

    if definition.select_type?
      labels = definition.attribute_options.index_by(&:value)
      values.map { |value| labels[value]&.label || value }.join(", ")
    elsif definition.boolean?
      raw.to_s == "true" ? t("listings.specs.yes") : t("listings.specs.no")
    else
      values.map { |value| [ value, definition.unit ].compact_blank.join(" ") }.join(", ")
    end
  end

  def spec_value(listing, definition)
    (listing.specs || {})[definition.key]
  end

  def product_labels(listing)
    listing.tags.select(&:product_label?)
  end

  def seller_tags(listing)
    listing.tags.select(&:seller_tag?)
  end

  def location_label(listing)
    listing.region&.name.presence || listing.city.presence ||
      t("countries.#{listing.country_code.to_s.downcase}")
  end

  def delivery_estimate_for(listing)
    DeliveryEstimate.new(handling_days: listing.handling_days)
  end

  def shipping_summary(listing)
    if listing.local_pickup?
      t("listings.show.shipping.pickup_only")
    elsif listing.free_shipping? || listing.shipping_price_cents.to_i.zero?
      t("listings.show.shipping.free")
    else
      t("listings.show.shipping.cost",
        price: money(listing.shipping_price_cents, currency: listing.currency))
    end
  end

  def short_date(date)
    l(date, format: :short)
  end

  def rating_stars(rating)
    full = rating.to_f.round.clamp(0, 5)
    Array.new(5) { |index| index < full ? "full" : "empty" }
  end

  def purchase_blocked_reason(listing)
    return :own_listing if user_signed_in? && listing.user_id == current_user.id
    return :store_vacation if listing.store&.vacation_mode?
    return :payouts_not_enabled unless listing.store&.payouts_ready?
    return :guest_disabled if !user_signed_in? && !Flipper.enabled?(:guest_checkout)
    return :out_of_stock if listing.quantity.to_i <= 0
    return :unavailable unless listing.publicly_visible?

    nil
  end

  def purchase_blocked_message(reason)
    t("cart.purchase_blocked.#{reason}")
  end
end
