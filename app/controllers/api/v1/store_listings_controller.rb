# frozen_string_literal: true

module Api
  module V1
    class StoreListingsController < BaseController
      def index
        store = Store.active.friendly.find(params[:store_id])
        result = ListingSearch.new(search_params, store: store).call
        cache_public_catalogue!

        set_pagination_headers(result.pagy)
        render_collection(
          result.listings, ListingCardSerializer,
          meta: collection_meta(
            result.pagy,
            extra: { facets: result.facets, applied_filters: result.applied_filters,
                     store_id: store.id }
          )
        )
      end

      private

      def search_params
        params.to_unsafe_h.except("controller", "action", "format", "store_id")
      end
    end
  end
end
