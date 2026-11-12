# frozen_string_literal: true

module PcFinder
  # Read-only data for the quiz landing page: style tiles, the sub-1000 € rail
  # and the "Best PCs for <game>" presets.
  class Landing
    RAIL_SIZE = 8

    def initialize
      @gaming = Category.active.find_by(slug: Recommend::GAMING_CATEGORY_SLUG)
    end

    def style_tiles
      return [] if @gaming.blank?

      tags = Tag.seller_tags.active.where(slug: Criteria::VIBES).ordered.to_a
      return [] if tags.empty?

      counts = Listing.visible.in_category(@gaming).joins(:tags)
                    .where(tags: { id: tags.map(&:id) })
                    .group("tags.id").count

      tags.filter_map do |tag|
        count = counts[tag.id].to_i
        next if count.zero?

        { tag: tag, count: count, path: links.pc_finder_path(vibe: tag.slug, locale: I18n.locale) }
      end
    end

    def under_1000
      return Listing.none if @gaming.blank?

      Listing.visible.in_category(@gaming)
             .where(price_cents: ...100_000)
             .with_card_includes
             .order(price_cents: :asc, id: :asc)
             .limit(RAIL_SIZE)
    end

    def best_games
      Game.active.ordered.includes(cover_attachment: :blob).limit(3).to_a
    end

    private

    def links
      Rails.application.routes.url_helpers
    end
  end
end
