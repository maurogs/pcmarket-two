# frozen_string_literal: true

module Api
  module V1
    class TagsController < BaseController
      def index
        cache_public_catalogue!
        collection_response(Catalogue.new.tags, TagSerializer)
      end
    end
  end
end
