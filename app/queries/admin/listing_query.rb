# frozen_string_literal: true

module Admin
  # Filtered, sorted and paginated listing index used by the admin panel.
  class ListingQuery
    include Filterable

    FILTERABLE_STATUSES = Listing::STATUSES
    FILTERABLE_CONDITIONS = Listing.conditions.keys
    STORE_KINDS = %w[individual business].freeze

    def filters
      {
        q: text_param(:q),
        status: enum_param(:status, FILTERABLE_STATUSES),
        category: category,
        seller_id: integer_param(:seller_id),
        store_kind: enum_param(:store_kind, STORE_KINDS),
        condition: enum_param(:condition, FILTERABLE_CONDITIONS),
        price_min: money_param(:price_min),
        price_max: money_param(:price_max),
        created_from: date_param(:created_from),
        created_to: date_param(:created_to),
        featured: boolean_param(:featured),
        has_reports: boolean_param(:has_reports)
      }
    end

    def relation
      @relation ||= apply_filters(
        Listing.includes(:seller, :store, :category, { photos: { image_attachment: :blob } })
      )
    end

    def sort_options
      {
        "created_at" => "listings.created_at",
        "updated_at" => "listings.updated_at",
        "published_at" => "listings.published_at",
        "title" => "listings.title",
        "price" => "listings.price_cents",
        "status" => "listings.status"
      }
    end

    def default_sort
      "created_at"
    end

    def categories
      @categories ||= Category.active.order(:depth, :position, :id).to_a
    end

    def sellers
      @sellers ||= User.where(id: Listing.distinct.select(:user_id)).order(:username).limit(500).to_a
    end

    private

    def category
      slug = text_param(:category, max: 160)
      slug.present? ? Category.active.find_by(slug: slug) : nil
    end

    def money_param(key)
      BigDecimal(text_param(key, max: 12).to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def apply_filters(scope)
      scope = filter_by_query(scope)
      scope = scope.where(status: filters[:status]) if filters[:status]
      scope = scope.in_category(filters[:category]) if filters[:category]
      scope = scope.where(user_id: filters[:seller_id]) if filters[:seller_id]
      scope = scope.joins(:store).where(stores: { kind: filters[:store_kind] }) if filters[:store_kind]
      scope = scope.where(condition: filters[:condition]) if filters[:condition]
      scope = filter_by_price(scope)
      scope = scope.where(created_at: created_range) if created_range
      scope = filter_by_featured(scope)
      filter_by_reports(scope)
    end

    def filter_by_query(scope)
      query = filters[:q]
      return scope if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      if query.match?(/\A\d+\z/)
        scope.where("listings.id = ? OR listings.title ILIKE ? OR listings.slug ILIKE ?", query.to_i, pattern, pattern)
      else
        scope.where("listings.title ILIKE :q OR listings.slug ILIKE :q", q: pattern)
      end
    end

    def filter_by_price(scope)
      min = filters[:price_min]
      max = filters[:price_max]
      return scope if min.nil? && max.nil?

      if min && max
        scope.where(price_cents: (min * 100).round..(max * 100).round)
      elsif min
        scope.where("listings.price_cents >= ?", (min * 100).round)
      else
        scope.where("listings.price_cents <= ?", (max * 100).round)
      end
    end

    def created_range
      from = filters[:created_from]
      to = filters[:created_to]
      return if from.nil? && to.nil?

      (from || Date.new(1970, 1, 1))..(to || Date.current)
    end

    def filter_by_featured(scope)
      case filters[:featured]
      when true then scope.featured
      when false then scope.where("listings.featured_until IS NULL OR listings.featured_until <= ?", Time.current)
      else scope
      end
    end

    def filter_by_reports(scope)
      case filters[:has_reports]
      when true
        scope.where(id: Report.where(reportable_type: "Listing").select(:reportable_id))
      when false
        scope.where.not(id: Report.where(reportable_type: "Listing").select(:reportable_id))
      else
        scope
      end
    end
  end
end
