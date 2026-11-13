# frozen_string_literal: true

# Live trust figures, cached for one hour. Each figure is hidden on the page
# until it clears a minimum that makes it meaningful.
class TrustStats
  CACHE_KEY = "trust/stats"
  MINIMUM_SALES = 25
  MINIMUM_SELLERS = 10
  MINIMUM_RATINGS_COUNT = 5
  MINIMUM_RATING = 4.0

  attr_reader :listings_sold, :active_sellers, :average_rating, :ratings_count

  def initialize(listings_sold: 0, active_sellers: 0, average_rating: 0, ratings_count: 0)
    @listings_sold = listings_sold.to_i
    @active_sellers = active_sellers.to_i
    @average_rating = average_rating.to_f
    @ratings_count = ratings_count.to_i
  end

  def self.call
    Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) do
      average, count = Review.visible_reviews.pick(
        Arel.sql("AVG(rating)"), Arel.sql("COUNT(*)")
      )

      {
        listings_sold: Listing.where(status: "sold").count,
        active_sellers: Store.active.count,
        average_rating: average.to_f.round(2),
        ratings_count: count.to_i
      }
    end
  end

  def self.current
    new(**call.symbolize_keys)
  end

  def show_listings_sold?
    listings_sold >= MINIMUM_SALES
  end

  def show_active_sellers?
    active_sellers >= MINIMUM_SELLERS
  end

  def show_rating?
    ratings_count >= MINIMUM_RATINGS_COUNT && average_rating >= MINIMUM_RATING
  end

  def any?
    show_listings_sold? || show_active_sellers? || show_rating?
  end
end
