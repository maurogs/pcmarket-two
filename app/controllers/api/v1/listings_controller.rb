# frozen_string_literal: true

module Api
  module V1
    class ListingsController < BaseController
      def index
        result = ListingSearch.new(search_params).call
        cache_public_catalogue!

        etag = [
          "api/v1/listings", I18n.locale, Listing.search_cache_version,
          request.query_string, current_user&.id
        ]
        return if conditional_get!(etag: etag, public: current_user.nil?)

        set_pagination_headers(result.pagy)
        listings = result.listings
        ActiveRecord::Associations::Preloader.new(
          records: listings, associations: { store: { logo_attachment: :blob } }
        ).call
        # Card payloads are read-only projections of public data. Cache the
        # hash per listing (keyed on the listing/store/category and locale) so
        # repeated listing feeds do not rebuild 96 signed variant URLs.
        data = listings.map do |listing|
          Rails.cache.fetch(
            [ "api/v1/listing_card", listing.cache_key_with_version,
              listing.store.cache_key_with_version, listing.category&.cache_key_with_version,
              I18n.locale, ListingCardSerializer.image_host, ListingCardSerializer.image_protocol ],
            expires_in: 60.seconds
          ) do
            ListingCardSerializer.new(listing).serializable_hash
          end
        end
        render_data(
          data,
          meta: collection_meta(
            result.pagy,
            extra: {
              facets: result.facets,
              applied_filters: result.applied_filters,
              category_id: result.category&.id,
              sort: result.sort
            }
          )
        )
      end

      def show
        listing = Listing.with_detail_includes.friendly.find(params[:id])
        raise ActiveRecord::RecordNotFound unless listing.visible_to?(current_user)

        return if conditional_get!(
          etag: [ listing, I18n.locale, current_user&.id ],
          last_modified: listing.updated_at,
          public: current_user.nil?
        )

        similar_ids = Listing.similar_to(listing, limit: 8).limit(8).pluck(:id)
        render_resource(
          listing, ListingDetailSerializer,
          options: { params: { similar_listing_ids: similar_ids } }
        )
      end

      private

      def search_params
        params.to_unsafe_h.except("controller", "action", "format")
      end
    end
  end
end
