# frozen_string_literal: true

module Admin
  # Owns the pending-review queue: filters, pagination and the neighbour
  # lookups used by the review page. The controller only renders the result.
  class ModerationQueue
    PER_PAGE = 20
    SELLER_KINDS = %w[individual business].freeze
    PHOTO_FILTERS = %w[with without].freeze
    ORDER_SQL = Arel.sql("submitted_at ASC NULLS LAST, id ASC")
    PREVIOUS_ORDER_SQL = Arel.sql("submitted_at DESC NULLS FIRST, id DESC")

    Result = Struct.new(:listings, :pagy, :categories, :filters, :profiles, keyword_init: true) do
      def profile_for(listing)
        profiles[listing] || SellerProfile.new(listing: listing)
      end
    end

    def initialize(params:)
      raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @params = raw_params.deep_stringify_keys
    end

    def call
      relation = filtered_relation
      total = relation.count
      pagy = build_pagy(total)
      listings = relation
                 .with_detail_includes
                 .order(ORDER_SQL)
                 .offset(pagy.offset)
                 .limit(pagy.limit)
                 .to_a
      rejection_counts = SellerProfile.rejection_counts(listings.map(&:user_id))
      profiles = listings.index_with do |listing|
        SellerProfile.new(listing: listing,
                          rejection_count: rejection_counts[listing.user_id] || 0)
      end

      Result.new(
        listings: listings,
        pagy: pagy,
        categories: Category.active.order(:depth, :position, :id).to_a,
        filters: filters,
        profiles: profiles
      )
    end

    def self.oldest_pending(limit: 10)
      pending_relation.with_detail_includes.order(ORDER_SQL).limit(limit).to_a
    end

    # The next item in oldest-first order, excluding the given listing. The
    # listing may already have left the queue, so the comparison uses its
    # submitted_at/id key rather than its current status.
    def self.next_pending(listing)
      submitted = listing.submitted_at
      relation = pending_relation.where.not(id: listing.id)

      relation = if submitted.nil?
        relation.where("listings.submitted_at IS NULL AND listings.id > ?", listing.id)
      else
        relation.where(
          "listings.submitted_at > :submitted OR " \
          "(listings.submitted_at = :submitted AND listings.id > :id) OR " \
          "listings.submitted_at IS NULL",
          submitted: submitted, id: listing.id
        )
      end

      relation.order(ORDER_SQL).first
    end

    def self.previous_pending(listing)
      submitted = listing.submitted_at
      relation = pending_relation.where.not(id: listing.id)

      relation = if submitted.nil?
        relation.where(
          "(listings.submitted_at IS NULL AND listings.id < ?) OR listings.submitted_at IS NOT NULL",
          listing.id
        )
      else
        relation.where(
          "listings.submitted_at < :submitted OR " \
          "(listings.submitted_at = :submitted AND listings.id < :id)",
          submitted: submitted, id: listing.id
        )
      end

      relation.order(PREVIOUS_ORDER_SQL).first
    end

    def self.pending_relation
      Listing.where(status: "pending_review")
    end

    private

    def filtered_relation
      relation = self.class.pending_relation
      relation = relation.in_category(category) if category
      relation = filter_by_seller_kind(relation)
      relation = filter_by_photos(relation)
      relation = filter_by_title(relation)
      relation
    end

    def category
      return @category if defined?(@category)

      slug = normalized_string(@params["category"])
      @category = slug.present? ? Category.active.find_by(slug: slug) : nil
    end

    def filter_by_seller_kind(relation)
      kind = normalized_string(@params["seller_kind"])
      return relation unless SELLER_KINDS.include?(kind)

      relation.joins(:store).where(stores: { kind: kind })
    end

    def filter_by_photos(relation)
      case normalized_string(@params["photos"])
      when "with"
        relation.where("EXISTS (SELECT 1 FROM listing_photos WHERE listing_photos.listing_id = listings.id)")
      when "without"
        relation.where("NOT EXISTS (SELECT 1 FROM listing_photos WHERE listing_photos.listing_id = listings.id)")
      else
        relation
      end
    end

    def filter_by_title(relation)
      query = normalized_query
      return relation if query.blank?

      relation.where("listings.title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query)}%")
    end

    def filters
      {
        q: normalized_query,
        category: category,
        seller_kind: SELLER_KINDS.include?(normalized_string(@params["seller_kind"])) ? normalized_string(@params["seller_kind"]) : nil,
        photos: PHOTO_FILTERS.include?(normalized_string(@params["photos"])) ? normalized_string(@params["photos"]) : nil
      }
    end

    def normalized_query
      raw = @params["q"]
      return if raw.is_a?(Array) || raw.is_a?(Hash)

      raw.to_s.strip.presence&.slice(0, 120)
    end

    def normalized_string(value)
      return if value.is_a?(Array) || value.is_a?(Hash)

      value.to_s.strip.presence
    end

    def normalized_page
      raw = @params["page"]
      return 1 unless raw.is_a?(String) || raw.is_a?(Numeric)

      value = Integer(raw, exception: false)
      value && value.positive? ? value : 1
    end

    def build_pagy(total)
      last_page = [ (total.to_f / PER_PAGE).ceil, 1 ].max
      Pagy.new(count: total, page: [ normalized_page, last_page ].min, limit: PER_PAGE)
    end
  end
end
