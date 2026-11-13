# frozen_string_literal: true

module Api
  module V1
    class RegionsController < BaseController
      def index
        cache_public_catalogue!
        collection_response(Catalogue.new.regions(params[:country] || "ES"), RegionSerializer)
      end
    end
  end
end
