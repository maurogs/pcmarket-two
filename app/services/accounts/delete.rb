# frozen_string_literal: true

module Accounts
  # GDPR deletion: soft-delete the account, anonymise personal data and archive
  # the seller's listings. Orders and reviews stay for legal retention.
  class Delete
    OPEN_ORDER_STATUSES = %w[paid shipped].freeze

    Result = Struct.new(:success, :error_key, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(user:)
      @user = user
    end

    def call
      return failure("account.deletion.open_orders") if open_orders?

      affected = []
      User.transaction do
        affected = archive_listings
        purge_attachments
        anonymise
      end

      recompute_counters(affected)
      refresh_store_counter

      Result.new(success: true)
    end

    private

    attr_reader :user

    def open_orders?
      Order.where(buyer_id: user.id, status: OPEN_ORDER_STATUSES).exists? ||
        (user.store.present? &&
          user.store.orders.where(status: OPEN_ORDER_STATUSES).exists?)
    end

    def archive_listings
      affected = []

      user.listings.where.not(status: "sold").find_each do |listing|
        next unless listing.may_archive?

        affected << [ listing.store_id, listing.category_id ]
        begin
          listing.archive!
        rescue ActiveRecord::RecordInvalid
          listing.archive_without_validation!
        end
      end

      affected
    end

    def refresh_store_counter
      return if user.store.blank?

      user.store.update_columns(
        listings_count: Listing.published.where(store_id: user.store.id).count,
        updated_at: Time.current
      )
    end

    # Archiving through the model already maintains both counters, but the
    # batch is recomputed as well so a partially failed run can never leave a
    # stale denormalised count behind.
    def recompute_counters(pairs)
      store_ids = pairs.map(&:first).compact.uniq
      category_ids = pairs.map(&:last).compact.uniq
      return if store_ids.empty? && category_ids.empty?

      if store_ids.any?
        counts = Listing.where(store_id: store_ids, status: "published").group(:store_id).count
        store_ids.each do |store_id|
          Store.where(id: store_id).update_all(listings_count: counts[store_id] || 0)
        end
      end

      return if category_ids.empty?

      counts = Listing.where(category_id: category_ids, status: "published").group(:category_id).count
      category_ids.each do |category_id|
        Category.where(id: category_id).update_all(listings_count: counts[category_id] || 0)
      end
    end

    def purge_attachments
      user.avatar.purge if user.avatar.attached?
      user.data_export.purge if user.data_export.attached?
    end

    def anonymise
      user.update_columns(
        first_name: nil,
        last_name: nil,
        phone: nil,
        email: "deleted-#{user.id}@deleted.pcmarket.invalid",
        unconfirmed_email: nil,
        deleted_at: Time.current,
        updated_at: Time.current
      )
    end

    def failure(key)
      Result.new(success: false, error_key: key)
    end
  end
end
