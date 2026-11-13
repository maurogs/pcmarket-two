# frozen_string_literal: true

module Api
  module V1
    class AttributeDefinitionsController < BaseController
      def index
        cache_public_catalogue!
        collection_response(
          Catalogue.new.attribute_definitions,
          AttributeDefinitionSerializer
        )
      end
    end
  end
end
