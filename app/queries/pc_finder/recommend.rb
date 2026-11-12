# frozen_string_literal: true

module PcFinder
  # The PC Finder results query. It starts from visible Gaming PC listings,
  # applies the hardest game requirement at the chosen resolution/FPS, the
  # budget and the optional case/cooling/vibe filters, then ranks by price to
  # performance with a small bonus for matching the requested look.
  class Recommend
    PER_PAGE = 12
    VIBE_BONUS_CENTS = 5_000
    COLOUR_BONUS_CENTS = 3_000
    GAMING_CATEGORY_SLUG = "gaming-pcs"

    Result = Struct.new(:listings, :pagy, :criteria, keyword_init: true) do
      def games
        criteria.games
      end

      def empty?
        listings.empty?
      end

      def total_count
        pagy.count
      end

      def next_page
        pagy.next
      end
    end

    def initialize(criteria, page: nil)
      @criteria = criteria
      @page = normalise_page(page)
    end

    def call
      category = Category.active.find_by(slug: GAMING_CATEGORY_SLUG)
      return empty_result if category.blank?

      relation = base_relation(category)
      total = relation.count
      pagy = Pagy.new(count: total, page: [ @page, last_page(total) ].min,
                      limit: PER_PAGE)

      Result.new(listings: relation.offset(pagy.offset).limit(PER_PAGE).to_a,
                 pagy: pagy, criteria: @criteria)
    end

    private

    def base_relation(category)
      relation = Listing.visible.in_category(category).with_card_includes
      relation = relation.where("listings.gpu_tier >= ?", @criteria.max_gpu_tier) if @criteria.max_gpu_tier.positive?
      relation = relation.where("listings.cpu_tier >= ?", @criteria.max_cpu_tier) if @criteria.max_cpu_tier.positive?
      relation = relation.where(price_cents: @criteria.budget_range) if @criteria.budget_range
      relation = relation.with_specs("case_form_factor" => @criteria.case_form_factors) if @criteria.case_form_factors.any?
      relation = relation.with_specs("case_colour" => [ @criteria.case_colour ]) if @criteria.case_colour.present?
      relation = relation.with_specs("cpu_cooler_type" => @criteria.cooler_types) if @criteria.cooler_types.any?
      relation.order(Arel.sql(order_sql))
    end

    # Price minus the small look-matching bonus. Cheapest that meets the
    # required tiers wins; a matching vibe/colour can move a listing a little.
    def order_sql
      conditions = []
      if @criteria.vibe.present?
        vibe = ActiveRecord::Base.connection.quote(@criteria.vibe)
        conditions << <<~SQL.squish
          CASE WHEN EXISTS (
            SELECT 1 FROM listing_tags lt
            INNER JOIN tags t ON t.id = lt.tag_id
            WHERE lt.listing_id = listings.id AND t.slug = #{vibe}
          ) THEN #{VIBE_BONUS_CENTS} ELSE 0 END
        SQL
      end
      if @criteria.case_colour.present?
        colour = ActiveRecord::Base.connection.quote(@criteria.case_colour)
        conditions << "CASE WHEN listings.specs->>'case_colour' = #{colour} THEN #{COLOUR_BONUS_CENTS} ELSE 0 END"
      end

      bonus = conditions.any? ? conditions.join(" + ") : "0"
      "(listings.price_cents - (#{bonus})) ASC, listings.price_cents ASC, listings.id ASC"
    end

    def empty_result
      Result.new(listings: [], pagy: Pagy.new(count: 0, page: 1, limit: PER_PAGE),
                 criteria: @criteria)
    end

    def normalise_page(value)
      page = value.to_i
      page.positive? ? page : 1
    end

    def last_page(total)
      [ (total.to_f / PER_PAGE).ceil, 1 ].max
    end
  end
end
