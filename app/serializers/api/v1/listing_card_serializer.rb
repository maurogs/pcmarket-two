# frozen_string_literal: true

module Api
  module V1
    class ListingCardSerializer < BaseSerializer
      attributes :id, :slug, :title, :price_cents, :compare_at_price_cents,
                 :currency, :condition, :status, :quantity, :shipping_mode,
                 :shipping_price_cents, :free_shipping, :city, :region_id,
                 :published_at, :views_count, :favorites_count, :allow_offers

      attribute :seller_id do |listing|
        listing.user_id
      end

      attribute :featured do |listing|
        listing.featured_until.present? && listing.featured_until > Time.current
      end

      attribute :discount_percent, &:discount_percent

      attribute :store do |listing|
        StoreSummarySerializer.new(listing.store).serializable_hash
      end

      attribute :category do |listing|
        CategorySerializer.new(listing.category).serializable_hash
      end

      many :tags, resource: TagSerializer

      attribute :primary_photo do |listing|
        photo = listing.photos.first
        photo ? ListingPhotoSerializer.new(photo).serializable_hash : nil
      end
    end
  end
end
