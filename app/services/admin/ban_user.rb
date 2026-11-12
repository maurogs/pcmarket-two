# frozen_string_literal: true

module Admin
  # Bans an account, removes its live listings from the marketplace and expires
  # its unpaid checkouts. The seller receives a translated email.
  class BanUser
    def initialize(user:, actor:, reason:)
      @user = user
      @actor = actor
      @reason = reason.to_s.strip
    end

    def call
      return false if @reason.blank?
      return false if @user.admin?

      User.transaction do
        @user.update!(banned_at: Time.current, ban_reason: @reason)
        archive_listings
        expire_pending_checkouts
      end

      AdminMailer.user_banned(@user, @reason).deliver_later
      true
    end

    def self.unban(user)
      user.update!(banned_at: nil, ban_reason: nil)
    end

    private

    def archive_listings
      @user.listings.where(status: %w[published reserved pending_review rejected draft]).find_each do |listing|
        next unless listing.may_archive?

        begin
          listing.archive!
        rescue ActiveRecord::RecordInvalid
          listing.archive_without_validation!
        end
      end
    end

    def expire_pending_checkouts
      Checkout.where(buyer_id: @user.id, status: "pending").find_each do |checkout|
        Checkouts::Expire.new(checkout: checkout).call
      end
    end
  end
end
