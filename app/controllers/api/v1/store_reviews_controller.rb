# frozen_string_literal: true

module Api
  module V1
    class StoreReviewsController < BaseController
      def index
        store = Store.active.friendly.find(params[:store_id])
        profile = StorefrontProfile.new(
          store: store,
          params: params.to_unsafe_h.merge("tab" => "reviews")
        ).call
        cache_public_catalogue!

        pagy = profile.review_pagy
        set_pagination_headers(pagy)
        render_collection(
          profile.reviews, ReviewSerializer,
          meta: collection_meta(
            pagy,
            extra: {
              store_id: store.id,
              sort: profile.review_sort,
              rating_distribution: profile.rating_distribution
            }
          )
        )
      end
    end
  end
end
