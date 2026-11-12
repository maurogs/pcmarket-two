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
        render_collection(
          result.listings, ListingCardSerializer,
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
