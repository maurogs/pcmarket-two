# frozen_string_literal: true

module Api
  module V1
    module PcFinder
      class RecommendationsController < BaseController
        def index
          criteria = ::PcFinder::Criteria.new(criteria_params)
          result = ::PcFinder::Recommend.new(
            criteria, page: params[:page], per_page: params[:per_page]
          ).call
          cache_public_catalogue!

          set_pagination_headers(result.pagy)
          render_collection(
            result.listings, ListingCardSerializer,
            meta: collection_meta(
              result.pagy,
              extra: { criteria: criteria.to_h }
            )
          )
        end

        private

        def criteria_params
          params.to_unsafe_h.except("controller", "action", "format")
        end
      end
    end
  end
end
