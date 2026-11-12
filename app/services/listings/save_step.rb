# frozen_string_literal: true

module Listings
  # Persists one wizard step: attributes, photo uploads, removals and ordering.
  # The listing is always validated against its step context so later steps do
  # not block earlier ones.
  class SaveStep
    def initialize(listing:, step:, attributes: {}, images: [], photo_signed_ids: [],
                   photo_order: [], remove_photo_ids: [])
      @listing = listing
      @step = step.to_s
      @attributes = attributes
      @images = Array(images).compact_blank
      @photo_signed_ids = Array(photo_signed_ids).compact_blank
      @photo_order = Array(photo_order).compact_blank
      @remove_photo_ids = Array(remove_photo_ids).compact_blank
    end

    def call
      return false unless Listing::WIZARD_STEPS.include?(step)

      saved = false
      Listing.transaction do
        listing.assign_attributes(attributes)
        remove_photos
        unless attach_images
          raise ActiveRecord::Rollback
        end
        order_photos

        saved = listing.save(context: step.to_sym)
        raise ActiveRecord::Rollback unless saved
      end
      saved
    rescue ActiveRecord::RecordInvalid => e
      listing.errors.add(:base, e.record.errors.full_messages.to_sentence)
      false
    end

    private

    attr_reader :listing, :step, :attributes, :images, :photo_signed_ids,
                :photo_order, :remove_photo_ids

    def remove_photos
      return if remove_photo_ids.empty?

      listing.photos.where(id: remove_photo_ids).destroy_all
    end

    def attach_images
      return true if images.empty? && photo_signed_ids.empty?
      return too_many_photos_error unless within_photo_limit?

      images.each do |image|
        photo = listing.photos.build
        photo.image.attach(image)
        next if photo.save

        photo.errors.full_messages.each { |message| listing.errors.add(:base, message) }
        raise ActiveRecord::Rollback
      end

      photo_signed_ids.each do |signed_id|
        blob = ActiveStorage::Blob.find_signed!(signed_id)
        photo = listing.photos.build
        photo.image.attach(blob)
        next if photo.save

        photo.errors.full_messages.each { |message| listing.errors.add(:base, message) }
        raise ActiveRecord::Rollback
      end

      true
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      listing.errors.add(:base, I18n.t("api.errors.invalid_signed_id"))
      false
    end

    def within_photo_limit?
      max = Setting.get(:max_images_per_listing, 12).to_i
      return true if max <= 0

      listing.photos.size + images.size + photo_signed_ids.size <= max
    end

    def too_many_photos_error
      max = Setting.get(:max_images_per_listing, 12).to_i
      listing.errors.add(:base, I18n.t("listings.errors.too_many_photos", max: max))
      false
    end

    def order_photos
      return if photo_order.empty?

      photos = listing.photos.index_by { |photo| photo.id.to_s }
      photo_order.each_with_index do |id, index|
        photos[id.to_s]&.update_column(:position, index)
      end
    end
  end
end
