# frozen_string_literal: true

module Api
  module V1
    class ListingPhotoSerializer < BaseSerializer
      attributes :id, :position

      attribute :thumb_url do |photo|
        attachment_url(photo.image, variant: :thumb)
      end
      attribute :card_url do |photo|
        attachment_url(photo.image, variant: :card)
      end
      attribute :large_url do |photo|
        attachment_url(photo.image, variant: :large)
      end
    end
  end
end
