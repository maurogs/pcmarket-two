# frozen_string_literal: true

module Admin
  # Archives, features or labels a batch of listings. Moderators may approve,
  # reject and archive; labelling and featuring stay admin-only and are checked
  # by the controller policy.
  class BulkListingAction
    OPERATIONS = %w[approve reject archive label feature].freeze

    Result = Struct.new(:operation, :affected, :skipped, keyword_init: true)

    def initialize(listings:, actor:, operation:, reason: nil, label_id: nil, days: nil)
      @listings = listings
      @actor = actor
      @operation = operation.to_s
      @reason = reason.to_s.strip
      @label_id = label_id
      @days = days.to_i
    end

    def call
      return Result.new(operation: @operation, affected: 0, skipped: @listings.size) unless OPERATIONS.include?(@operation)

      affected = 0
      skipped = 0

      @listings.find_each do |listing|
        if perform(listing)
          affected += 1
        else
          skipped += 1
        end
      end

      Result.new(operation: @operation, affected: affected, skipped: skipped)
    end

    private

    def perform(listing)
      case @operation
      when "approve" then approve(listing)
      when "reject" then reject(listing)
      when "archive" then archive(listing)
      when "label" then label(listing)
      when "feature" then feature(listing)
      end
    end

    def approve(listing)
      Listings::Moderate.new(listing: listing, moderator: @actor).approve!.present?
    end

    def reject(listing)
      return false if @reason.blank?

      Listings::Moderate.new(listing: listing, moderator: @actor, reason: @reason).reject!.present?
    end

    def archive(listing)
      return false unless listing.may_archive?

      begin
        listing.archive!
      rescue ActiveRecord::RecordInvalid
        listing.archive_without_validation!
      end
      true
    end

    def label(listing)
      tag = Tag.product_labels.active.find_by(id: @label_id)
      return false if tag.blank?

      listing.listing_tags.find_or_create_by!(tag: tag)
      true
    end

    def feature(listing)
      return false unless @days.positive?

      listing.update_columns(featured_until: @days.days.from_now, updated_at: Time.current)
      true
    end
  end
end
