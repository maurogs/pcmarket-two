# frozen_string_literal: true

module Api
  module V1
    class CountriesController < BaseController
      def index
        cache_public_catalogue!
        collection_response(Catalogue.new.countries, CountrySerializer)
      end
    end
  end
end
