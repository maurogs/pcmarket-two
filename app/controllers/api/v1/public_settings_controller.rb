# frozen_string_literal: true

module Api
  module V1
    class PublicSettingsController < BaseController
      def show
        cache_public_catalogue!
        render_data(Catalogue.new.public_settings)
      end
    end
  end
end
