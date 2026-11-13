# frozen_string_literal: true

# Read-only data for the cached home page sections. Every method returns a
# Relation or Array that is already eager-loaded for the listing card, so the
# view never issues a query per card.
class HomeFeed
  RAIL_SIZE = 10
  TILE_SIZE = 4
  CAROUSEL_SIZE = 6
  STYLE_TAG_SLUGS = %w[minimalist anime rgb whiteout compact retro].freeze

  CATEGORY_SLUGS = {
    gaming_pcs: "gaming-pcs",
    gpus: "graphics-cards",
    laptops: "laptops",
    phones: "phones",
    tablets: "tablets",
    consoles: "consoles"
  }.freeze

  def initialize
    @categories = Category.active.where(slug: CATEGORY_SLUGS.values).index_by(&:slug)
  end

  def categories
    @categories
  end

  # Featured listings first; if there are none, the biggest discounts.
  def deals_of_day
    @deals_of_day ||= begin
      featured = visible_with_cards.featured.order(featured_until: :desc, id: :desc).limit(CAROUSEL_SIZE)
      if featured.any?
        featured.to_a
      else
        discounted.order(Arel.sql("(compare_at_price_cents - price_cents)::float / compare_at_price_cents DESC"))
          .limit(CAROUSEL_SIZE).to_a
      end
    end
  end

  def most_wanted
    ids = Favourite.where(created_at: 1.week.ago..)
                   .group(:listing_id)
                   .order(Arel.sql("COUNT(*) DESC"))
                   .limit(TILE_SIZE)
                   .pluck(:listing_id)
    ordered_by_ids(visible_with_cards.where(id: ids), ids)
  end

  def ready_to_ship
    gaming = category(:gaming_pcs)
    return [] if gaming.blank?

    visible_with_cards.in_category(gaming)
                      .where(handling_days: 1..2)
                      .order(published_at: :desc, id: :desc)
                      .limit(TILE_SIZE).to_a
  end

  def deals
    discounted.order(published_at: :desc, id: :desc).limit(TILE_SIZE).to_a
  end

  def style_tiles
    gaming = category(:gaming_pcs)
    return [] if gaming.blank?

    tags = Tag.seller_tags.active.where(slug: STYLE_TAG_SLUGS).ordered.to_a
    return [] if tags.empty?

    counts = Listing.visible.in_category(gaming)
                    .joins(:tags)
                    .where(tags: { id: tags.map(&:id) })
                    .group("tags.id").count

    tags.filter_map do |tag|
      count = counts[tag.id].to_i
      next if count.zero?

      {
        tag: tag,
        count: count,
        path: Rails.application.routes.url_helpers.category_path(
          gaming, tags: [ tag.slug ], locale: I18n.locale
        )
      }
    end
  end

  def new_gpus
    rail(:gpus)
  end

  def most_watched
    ids = ListingView.where(date: 7.days.ago.to_date..Date.current)
                     .group(:listing_id)
                     .order(Arel.sql("SUM(views) DESC"))
                     .limit(60)
                     .pluck(:listing_id)
    ordered_by_ids(visible_with_cards.where(id: ids), ids).first(RAIL_SIZE)
  end

  def on_sale
    discounted.order(published_at: :desc, id: :desc).limit(RAIL_SIZE).to_a
  end

  def latest_laptops
    rail(:laptops)
  end

  def latest_phones_and_tablets
    categories = [ category(:phones), category(:tablets) ].compact
    return [] if categories.empty?

    visible_with_cards.in_category(categories).order(published_at: :desc, id: :desc)
                      .limit(RAIL_SIZE).to_a
  end

  def latest_consoles
    rail(:consoles)
  end

  def recently_sold
    Listing.where(status: "sold")
           .where(sold_at: 90.days.ago..)
           .where(country_code: Country.launched_codes)
           .joins(:store).merge(Store.active)
           .joins(:seller).where(users: { banned_at: nil, deleted_at: nil })
           .with_card_includes
           .order(sold_at: :desc, id: :desc)
           .limit(RAIL_SIZE).to_a
  end

  def testimonials
    Review.visible_reviews
          .where(rating: 5)
          .where("LENGTH(reviews.body) > 80")
          .newest_first
          .with_reviewer
          .includes(:store)
          .limit(3).to_a
  end

  def any_promo_tiles?
    most_wanted.any? || ready_to_ship.any? || deals.any?
  end

  def sell_to_us?
    Flipper.enabled?(:sell_to_us)
  end

  private

  def category(key)
    @categories[CATEGORY_SLUGS.fetch(key)]
  end

  def rail(key)
    category_record = category(key)
    return [] if category_record.blank?

    visible_with_cards.in_category(category_record)
                      .order(published_at: :desc, id: :desc)
                      .limit(RAIL_SIZE).to_a
  end

  def discounted
    visible_with_cards.where.not(compare_at_price_cents: nil)
                      .where("compare_at_price_cents > price_cents")
  end

  def visible_with_cards
    Listing.visible.with_card_includes
  end

  def ordered_by_ids(relation, ids)
    records = relation.to_a.index_by(&:id)
    ids.filter_map { |id| records[id] }
  end
end
