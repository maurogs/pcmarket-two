# frozen_string_literal: true

# Loads everything the public storefront needs for one tab: the scoped listing
# search, recently sold items, the review page and the header counters.
class StorefrontProfile
  TABS = %w[listings about reviews].freeze
  REVIEW_SORTS = %w[newest highest lowest].freeze
  REVIEWS_PER_PAGE = 10
  SOLD_LIMIT = 8

  Result = Struct.new(
    :store,
    :tab,
    :search,
    :categories,
    :sold_listings,
    :reviews,
    :review_pagy,
    :review_sort,
    :rating_distribution,
    :for_sale_count,
    :sold_count,
    keyword_init: true
  )

  def initialize(store:, params:)
    @store = store
    @params = params.respond_to?(:to_h) ? params.to_h.deep_stringify_keys : {}
    @tab = TABS.include?(@params["tab"].to_s) ? @params["tab"].to_s : "listings"
    @review_sort = REVIEW_SORTS.include?(@params["review_sort"].to_s) ? @params["review_sort"].to_s : "newest"
  end

  def call
    Result.new(
      store: @store,
      tab: @tab,
      search: listings_tab? ? search : nil,
      categories: listings_tab? ? categories : [],
      sold_listings: listings_tab? ? sold_listings : [],
      reviews: reviews_tab? ? reviews : [],
      review_pagy: reviews_tab? ? review_pagy : nil,
      review_sort: @review_sort,
      rating_distribution: reviews_tab? ? rating_distribution : {},
      for_sale_count: for_sale_count,
      sold_count: sold_count
    )
  end

  private

  def listings_tab?
    @tab == "listings"
  end

  def reviews_tab?
    @tab == "reviews"
  end

  def search
    @search ||= ListingSearch.new(@params, store: @store).call
  end

  def categories
    @categories ||= Category.where(id: Listing.visible.where(store_id: @store.id).select(:category_id))
                            .order(:position, :id)
                            .to_a
  end

  def sold_listings
    @sold_listings ||= @store.listings.where(status: "sold")
                               .with_card_includes
                               .order(sold_at: :desc, id: :desc)
                               .limit(SOLD_LIMIT)
                               .to_a
  end

  def reviews
    review_relation.with_reviewer.offset(review_pagy.offset).limit(review_pagy.limit).to_a
  end

  def review_relation
    @review_relation ||= @store.reviews.visible_reviews.sorted_by(@review_sort)
  end

  def review_pagy
    @review_pagy ||= begin
      total = review_relation.count
      last_page = [ (total.to_f / REVIEWS_PER_PAGE).ceil, 1 ].max
      page = [ @params["page"].to_i, 1 ].max
      Pagy.new(count: total, page: [ page, last_page ].min, limit: REVIEWS_PER_PAGE)
    end
  end

  def rating_distribution
    @rating_distribution ||= begin
      counts = @store.reviews.visible_reviews.group(:rating).count
      (1..5).to_a.reverse.index_with { |rating| counts[rating].to_i }
    end
  end

  def for_sale_count
    @for_sale_count ||= Listing.visible.where(store_id: @store.id).count
  end

  def sold_count
    @sold_count ||= @store.listings.where(status: "sold").count
  end
end
