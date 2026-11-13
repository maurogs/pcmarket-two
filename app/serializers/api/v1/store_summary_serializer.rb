# frozen_string_literal: true

module Api
  module V1
    class StoreSummarySerializer < BaseSerializer
      attributes :id, :name, :slug, :kind, :city, :province, :country_code,
                 :rating_average, :ratings_count, :listings_count

      attribute :verified, &:verified?
      attribute :logo_url do |store|
        attachment_url(store.logo, variant: { resize_to_limit: [ 192, 192 ], format: :webp })
      end
    end
  end
end
