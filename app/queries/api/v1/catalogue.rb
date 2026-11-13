# frozen_string_literal: true

module Api
  module V1
    # Read-only catalogue data with the same caching rules as the HTML pages.
    class Catalogue
      CATEGORY_TREE_TTL = 5.minutes

      def categories_tree
        Rails.cache.fetch(
          [ "api/v1/categories", I18n.locale, Category.tree_cache_version ],
          expires_in: CATEGORY_TREE_TTL
        ) do
          roots = Category.active.roots.includes(:children).order(:position, :id).to_a
          roots.map { |category| CategorySerializer.new(category).serializable_hash }
        end
      end

      def attribute_definitions
        AttributeDefinition.active.ordered.includes(:attribute_options).to_a
      end

      def tags
        Tag.active.ordered.to_a
      end

      def regions(country_code)
        code = country_code.to_s.upcase.presence || "ES"
        return Region.none unless Country.exists?(code: code)

        Region.for_country(code).ordered
      end

      def countries
        Country.active.ordered
      end

      def public_settings
        {
          min_price_cents: Setting.get(:min_listing_price, 1).to_i * 100,
          max_price_cents: Setting.get(:max_listing_price, 50_000).to_i * 100,
          buyer_protection_days: Setting.get(:buyer_protection_days, 2).to_i,
          currency: "EUR",
          features: {
            offers: Flipper.enabled?(:offers),
            guest_checkout: Flipper.enabled?(:guest_checkout),
            sell_to_us: Flipper.enabled?(:sell_to_us)
          }
        }
      end
    end
  end
end
