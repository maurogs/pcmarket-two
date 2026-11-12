# frozen_string_literal: true

module Api
  module V1
    class FavouriteSerializer < BaseSerializer
      attributes :id, :listing_id, :created_at

      attribute :listing do |favourite|
        ListingCardSerializer.new(favourite.listing).serializable_hash
      end
    end
  end
end
