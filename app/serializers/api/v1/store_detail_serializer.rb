# frozen_string_literal: true

module Api
  module V1
    class StoreDetailSerializer < BaseSerializer
      attributes :id, :name, :slug, :description, :kind, :status, :city,
                 :province, :country_code, :region_id, :handling_days,
                 :return_policy, :shipping_policy, :rating_average,
                 :ratings_count, :listings_count, :followers_count,
                 :vacation_mode, :vacation_message, :vacation_until,
                 :created_at

      attribute :verified, &:verified?
      attribute :logo_url do |store|
        attachment_url(store.logo, variant: { resize_to_limit: [ 384, 384 ], format: :webp })
      end
      attribute :banner_url do |store|
        attachment_url(store.banner, variant: { resize_to_limit: [ 1600, 480 ], format: :webp })
      end
      attribute :user do |store|
        UserSummarySerializer.new(store.user).serializable_hash
      end
      attribute :for_sale_count do |store|
        Listing.visible.where(store_id: store.id).count
      end
      attribute :sold_count do |store|
        store.listings.where(status: "sold").count
      end
    end
  end
end
