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

      User.transaction do
        archive_listings
        purge_attachments
        anonymise
      end

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
      user.listings.where.not(status: "sold").update_all(
        status: "archived",
        archived_at: Time.current,
        updated_at: Time.current
      )

      return if user.store.blank?

      user.store.update_columns(
        listings_count: Listing.visible.where(store_id: user.store.id).count,
        updated_at: Time.current
      )
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
