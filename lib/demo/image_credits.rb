# frozen_string_literal: true

module Demo
  # Reads the attribution metadata stored on Active Storage blobs when the demo
  # seed attaches a downloaded photo. Only images that are actually attached to
  # a listing or storefront appear on the credits page.
  class ImageCredits
    CACHE_KEY = "demo/image_credits"
    CACHE_TTL = 10.minutes

    Entry = Struct.new(:provider, :author, :author_url, :license, :license_url,
                       :source_url, :title, keyword_init: true)

    def self.entries
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { new.entries }
    end

    def self.any?
      entries.any?
    end

    def entries
      blobs.map do |blob|
        metadata = blob.metadata.to_h.stringify_keys
        Entry.new(
          provider: metadata["demo_provider"],
          author: metadata["demo_author"],
          author_url: metadata["demo_author_url"],
          license: metadata["demo_license"],
          license_url: metadata["demo_license_url"],
          source_url: metadata["demo_source_url"],
          title: metadata["demo_title"]
        )
      end
    end

    private

    def blobs
      ActiveStorage::Blob
        .joins(:attachments)
        .where(active_storage_attachments: { record_type: %w[ListingPhoto Store] })
        .distinct
        .to_a
        .select { |blob| blob.metadata.to_h.stringify_keys["demo_provider"].present? }
        .sort_by do |blob|
          metadata = blob.metadata.to_h.stringify_keys
          [ metadata["demo_provider"].to_s, metadata["demo_author"].to_s, blob.id ]
        end
    end
  end
end
