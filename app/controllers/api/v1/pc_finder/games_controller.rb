# frozen_string_literal: true

module Api
  module V1
    module PcFinder
      class GamesController < BaseController
        def index
          cache_public_catalogue!
          collection_response(Game.active.ordered, GameSerializer)
        end
      end
    end
  end
end
