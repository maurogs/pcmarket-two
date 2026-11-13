# frozen_string_literal: true

class ListingPhoto < ApplicationRecord
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic].freeze
  IMAGE_MAX_SIZE = 15.megabytes

  belongs_to :listing, inverse_of: :photos

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 320, 320 ], format: :webp
    attachable.variant :card, resize_to_limit: [ 640, 640 ], format: :webp
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ], format: :webp
  end

  validates :image,
            content_type: { in: IMAGE_CONTENT_TYPES, message: :invalid_image_type },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE, message: :image_too_large }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :within_photo_limit

  before_validation :assign_position, on: :create

  after_commit :request_listing_review, on: %i[create destroy]

  private

  def assign_position
    return if position.present? && position.positive?

    self.position = (listing&.photos&.maximum(:position) || -1) + 1
  end

  def within_photo_limit
    return if listing.blank?

    max = Setting.get(:max_images_per_listing, 12).to_i
    return if max <= 0

    return if photo_count <= max

    errors.add(:base, I18n.t("listings.errors.too_many_photos", max: max))
  end

  def photo_count
    return listing.photos.size if listing.photos.loaded?

    listing.photos.count + (new_record? ? 1 : 0)
  end

  def request_listing_review
    listing&.reopen_for_review_after_photo_change!
  end
end
