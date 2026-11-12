# frozen_string_literal: true

require "digest"

# Turns an untrusted params hash into a visible, paginated listing relation
# plus the facets and active-filter metadata needed by the results UI.
#
# Facet policy: counts are computed over the fully filtered relation, including
# each attribute's own selection. Choosing this (instead of excluding the
# attribute's own filter) keeps the implementation to a single SQL query: a
# multi-select checkbox shows how many results remain with the current
# selection set, and options that would return nothing are disabled.
class ListingSearch
  PER_PAGE = 24
  SORTS = %w[best_match newest price_asc price_desc popular].freeze
  FACET_CACHE_TTL = 5.minutes

  Result = Struct.new(
    :listings,
    :pagy,
    :total_count,
    :facets,
    :applied_filters,
    :category,
    :sort,
    :query,
    :filterable_definitions,
    :attribute_definitions,
    :attribute_definitions_by_category,
    :selected_conditions,
    :selected_specs,
    :selected_tags,
    :selected_region,
    :free_shipping,
    :min_price,
    :max_price,
    :regions,
    :product_labels,
    :seller_tags,
    keyword_init: true
  ) do
    def filtered?
      !!@filtered
    end

    def filtered=(value)
      @filtered = value
    end

    def active_filter_count
      applied_filters.count { |filter| filter[:key].to_s != "q" }
    end
  end

  def initialize(raw_params, category: nil)
    @params = raw_params.to_h.deep_stringify_keys
    @explicit_category = category
    @query = normalized_query
    @min_price, @min_cents = normalized_price(:min_price)
    @max_price, @max_cents = normalized_price(:max_price)
    swap_prices_if_inverted
    @sort = normalized_sort
    @page = normalized_page
    @region_id = normalized_region
    @free_shipping = ActiveModel::Type::Boolean.new.cast(@params["free_shipping"]).present?
    @selected_conditions = normalized_conditions
    @raw_specs = @params["specs"]
    @tag_slugs = normalized_tags
  end

  def call
    category = resolve_category
    @resolved_category = category
    definitions = category ? category.effective_attribute_definitions : []
    @filterable_definitions = definitions.select(&:filterable?)
    @allowed_spec_keys = @filterable_definitions.index_by(&:key)
    @selected_specs = normalized_specs
    tags = Tag.active.ordered.to_a
    @tag_slugs &= tags.map(&:slug)
    regions = Region.for_country("ES").ordered.to_a
    @region_id = nil unless regions.any? { |region| region.id == @region_id }

    relation = filtered_relation(category)
    total_count = relation.count
    sorted_relation = sort_relation(relation)
    pagy = build_pagy(total_count)
    listings = sorted_relation.with_card_includes.offset(pagy.offset).limit(pagy.limit).to_a

    Result.new(
      listings: listings,
      pagy: pagy,
      total_count: total_count,
      facets: cached_facets(relation, definitions),
      applied_filters: build_applied_filters(tags, regions),
      category: category,
      sort: @sort,
      query: @query,
      filterable_definitions: @filterable_definitions,
      attribute_definitions: definitions,
      attribute_definitions_by_category: definitions_for_cards(listings, category, definitions),
      selected_conditions: @selected_conditions,
      selected_specs: @selected_specs,
      selected_tags: tags.select { |tag| @tag_slugs.include?(tag.slug) },
      selected_region: regions.find { |region| region.id == @region_id },
      free_shipping: @free_shipping,
      min_price: @min_price,
      max_price: @max_price,
      regions: regions,
      product_labels: tags.select(&:product_label?),
      seller_tags: tags.select(&:seller_tag?)
    ).tap { |result| result.filtered = filtered? }
  end

  private

  def filtered_relation(category)
    relation = Listing.visible
    relation = relation.search_text(@query) if @query.present?
    relation = relation.in_category(category) if category
    relation = apply_price_filters(relation)
    relation = relation.by_condition(@selected_conditions) if @selected_conditions.any?
    relation = relation.with_specs(@selected_specs) if @selected_specs.any?
    relation = apply_tag_filter(relation)
    relation = relation.in_region(@region_id) if @region_id
    relation = relation.where(free_shipping: true) if @free_shipping
    relation
  end

  def apply_price_filters(relation)
    relation = relation.where(price_cents: @min_cents..) if @min_cents
    relation = relation.where(price_cents: ..@max_cents) if @max_cents
    relation
  end

  def apply_tag_filter(relation)
    return relation if @tag_slugs.empty?

    relation.where(id: ListingTag.joins(:tag).where(tags: { slug: @tag_slugs }).select(:listing_id))
  end

  def sort_relation(relation)
    sort_key = if @sort == "best_match"
      @query.present? ? "relevance" : "newest"
    else
      @sort
    end

    relation.sorted_by(sort_key)
  end

  def build_pagy(total_count)
    last_page = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    Pagy.new(count: total_count, page: [ @page, last_page ].min, limit: PER_PAGE)
  end

  def resolve_category
    return @explicit_category if @explicit_category

    slug = @params["category"].to_s.strip
    return if slug.blank?

    Category.active.friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Batch-loads attribute definitions for every category shown on the page so
  # search results spanning categories do not trigger one query per card.
  def definitions_for_cards(listings, current_category, current_definitions)
    categories = listings.map(&:category).compact.uniq(&:id)
    result = {}
    result[current_category.id] = current_definitions if current_category
    pending = categories.reject { |category| result.key?(category.id) }
    return result if pending.empty?

    parents = Category.pluck(:id, :parent_id).to_h
    ids_by_category = pending.index_with { |category| ancestor_chain(category.id, parents) }
    links = CategoryAttribute
            .where(category_id: ids_by_category.values.flatten.uniq)
            .includes(attribute_definition: :attribute_options)
            .order(:position, :id)
            .to_a
            .group_by(&:category_id)

    ids_by_category.each do |category_id, ids|
      result[category_id] = ids
                            .flat_map { |id| links[id] || [] }
                            .sort_by { |link| [ link.position, link.id ] }
                            .map(&:attribute_definition)
                            .uniq(&:id)
    end

    result
  end

  def ancestor_chain(category_id, parents)
    ids = []
    node = category_id
    guard = 0
    while node && guard < 20
      ids << node
      node = parents[node]
      guard += 1
    end
    ids
  end

  def normalized_query
    raw = @params["q"]
    return if raw.is_a?(Array) || raw.is_a?(Hash)

    raw.to_s.strip.presence&.slice(0, 120)
  end

  def normalized_price(key)
    raw = @params[key.to_s]
    return [ nil, nil ] unless raw.is_a?(String) || raw.is_a?(Numeric)

    number = Float(raw, exception: false)
    return [ nil, nil ] if number.nil? || !number.finite? || number.negative?

    cents = (number * 100).round
    [ number, cents ]
  end

  def swap_prices_if_inverted
    return if @min_cents.nil? || @max_cents.nil? || @min_cents <= @max_cents

    @min_price, @max_price = @max_price, @min_price
    @min_cents, @max_cents = @max_cents, @min_cents
  end

  def normalized_sort
    value = @params["sort"].to_s
    SORTS.include?(value) ? value : "best_match"
  end

  def normalized_page
    raw = @params["page"]
    return 1 unless raw.is_a?(String) || raw.is_a?(Numeric)

    value = Integer(raw, exception: false)
    value && value.positive? ? value : 1
  end

  def normalized_region
    raw = @params["region"]
    return unless raw.is_a?(String) || raw.is_a?(Numeric)

    value = Integer(raw, exception: false)
    value && value.positive? ? value : nil
  end

  def normalized_conditions
    Array(@params["condition"]).map(&:to_s) & Listing.conditions.keys
  end

  def normalized_specs
    raw = @raw_specs
    return {} unless raw.is_a?(Hash)

    raw.each_with_object({}) do |(key, values), result|
      key = key.to_s
      next unless spec_key_allowed?(key)

      filtered = Array(values).map(&:to_s).reject(&:empty?).uniq
      result[key] = filtered if filtered.any?
    end
  end

  def spec_key_allowed?(key)
    return false if @allowed_spec_keys.blank?

    @allowed_spec_keys.key?(key)
  end

  def normalized_tags
    raw = @params["tags"]
    return [] unless raw.is_a?(Array)

    raw.map(&:to_s).reject(&:empty?).uniq.first(20)
  end

  def filtered?
    @query.present? || @min_cents.present? || @max_cents.present? ||
      @selected_conditions.any? || @selected_specs.any? || @tag_slugs.any? ||
      @region_id.present? || @free_shipping || @sort != "best_match"
  end

  # One SQL round trip for every attribute option count and the condition
  # counts. The filtered relation is materialised once in a CTE so the same
  # result set feeds both branches.
  def cached_facets(relation, definitions)
    digest = Digest::SHA1.hexdigest(facet_params.to_json)
    key = [ "listing_search/facets", Listing.search_cache_version, digest ]

    Rails.cache.fetch(key, expires_in: FACET_CACHE_TTL) do
      query_facets(relation, definitions)
    end
  end

  # Page and sort do not change facet counts, so they are deliberately omitted
  # from the cache key to improve the hit rate.
  def facet_params
    {
      q: @query,
      category: @resolved_category&.id || @params["category"],
      min_price: @min_price,
      max_price: @max_price,
      condition: @selected_conditions.sort,
      specs: @selected_specs.sort.to_h { |key, values| [ key, values.sort ] },
      tags: @tag_slugs.sort,
      region: @region_id,
      free_shipping: @free_shipping
    }
  end

  def query_facets(relation, definitions)
    select_definitions = definitions.select { |definition| definition.filterable? && definition.select_type? }
    ids_sql = relation.except(:select).select("listings.id").unscope(:order).to_sql
    conditions_sql = condition_counts_sql
    attributes_sql = attribute_counts_sql(select_definitions)
    union_sql = attributes_sql.present? ? "#{attributes_sql} UNION ALL #{conditions_sql}" : conditions_sql
    sql = "WITH filtered AS MATERIALIZED (#{ids_sql}) #{union_sql}"

    facets = { conditions: empty_condition_counts, attributes: {} }
    ActiveRecord::Base.connection.exec_query(sql).each do |row|
      if row["facet_type"] == "condition"
        facets[:conditions][row["option_value"]] = row["total"].to_i
      else
        facets[:attributes][row["attribute_key"]] ||= {}
        facets[:attributes][row["attribute_key"]][row["option_value"]] = row["total"].to_i
      end
    end

    fill_missing_facet_options(facets, select_definitions)
    facets
  end

  def condition_counts_sql
    when_clauses = Listing.conditions.map do |name, value|
      "WHEN #{value.to_i} THEN #{ActiveRecord::Base.connection.quote(name.to_s)}"
    end.join(" ")

    <<~SQL.squish
      SELECT 'condition' AS facet_type,
             'condition' AS attribute_key,
             CASE listings.condition #{when_clauses} END AS option_value,
             COUNT(*) AS total
      FROM listings
      INNER JOIN filtered ON filtered.id = listings.id
      GROUP BY listings.condition
    SQL
  end

  def attribute_counts_sql(definitions)
    return "" if definitions.empty?

    keys = definitions.map(&:key)
    quoted_keys = keys.map { |key| ActiveRecord::Base.connection.quote(key) }.join(", ")

    <<~SQL.squish
      SELECT 'attribute' AS facet_type,
             specs.key AS attribute_key,
             option.value AS option_value,
             COUNT(*) AS total
      FROM listings
      INNER JOIN filtered ON filtered.id = listings.id
      CROSS JOIN LATERAL jsonb_each(listings.specs) AS specs(key, value)
      CROSS JOIN LATERAL jsonb_array_elements_text(
        CASE
          WHEN jsonb_typeof(specs.value) = 'array' THEN specs.value
          ELSE jsonb_build_array(specs.value)
        END
      ) AS option(value)
      WHERE specs.key IN (#{quoted_keys})
      GROUP BY specs.key, option.value
    SQL
  end

  def fill_missing_facet_options(facets, definitions)
    definitions.each do |definition|
      counts = facets[:attributes][definition.key] ||= {}
      definition.attribute_options.select(&:active?).each do |option|
        counts[option.value] = 0 unless counts.key?(option.value)
      end
    end
  end

  def empty_condition_counts
    Listing.conditions.keys.index_with(0)
  end

  def build_applied_filters(tags, regions)
    filters = []
    filters << applied_filter("q", I18n.t("listings.filters.applied.q", query: @query)) if @query.present?
    filters << applied_filter("min_price", I18n.t("listings.filters.applied.min_price", value: format("%g", @min_price))) if @min_price
    filters << applied_filter("max_price", I18n.t("listings.filters.applied.max_price", value: format("%g", @max_price))) if @max_price
    @selected_conditions.each do |condition|
      filters << applied_filter("condition", I18n.t("listings.conditions.#{condition}"), condition)
    end
    @selected_specs.each do |key, values|
      definition = @allowed_spec_keys[key]
      next unless definition

      values.each do |value|
        label = definition.attribute_options.find { |option| option.value == value }&.label || value
        filters << applied_filter("specs", "#{definition.name}: #{label}", [ key, value ])
      end
    end
    @tag_slugs.each do |slug|
      tag = tags.find { |candidate| candidate.slug == slug }
      next unless tag

      filters << applied_filter("tags", tag.name, tag.slug)
    end
    if @region_id
      region = regions.find { |candidate| candidate.id == @region_id }
      filters << applied_filter("region", region.name) if region
    end
    filters << applied_filter("free_shipping", I18n.t("listings.filters.free_shipping")) if @free_shipping
    filters
  end

  def applied_filter(key, label, value = nil)
    {
      key: key,
      label: label,
      value: value,
      remove_params: remove_params(key, value)
    }
  end

  def remove_params(key, value)
    params = base_params.deep_dup

    case key
    when "condition", "tags"
      values = Array(params[key]) - [ value ]
      values.any? ? params[key] = values : params.delete(key)
    when "specs"
      spec_key, option = value
      specs = params["specs"].deep_dup
      options = Array(specs[spec_key]) - [ option ]
      options.any? ? specs[spec_key] = options : specs.delete(spec_key)
      specs.any? ? params["specs"] = specs : params.delete("specs")
    else
      params.delete(key)
    end

    params.delete("page")
    params
  end

  def base_params
    params = {}
    params["q"] = @query if @query.present?
    params["category"] = @params["category"].to_s.strip if @explicit_category.nil? && @resolved_category && @params["category"].present?
    params["min_price"] = @min_price if @min_price
    params["max_price"] = @max_price if @max_price
    params["condition"] = @selected_conditions if @selected_conditions.any?
    params["specs"] = @selected_specs if @selected_specs.any?
    params["tags"] = @tag_slugs if @tag_slugs.any?
    params["region"] = @region_id if @region_id
    params["free_shipping"] = "1" if @free_shipping
    params["sort"] = @sort if @sort != "best_match"
    params
  end
end
