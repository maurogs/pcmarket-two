# frozen_string_literal: true

module Admin
  class ListingRejectionsController < BaseController
    def create
      listing = Listing.friendly.find(params[:listing_id])
      authorize listing, :reject?, policy_class: Admin::ListingPolicy

      reason = ListingModeration.compose_reason(
        code: params[:reason_code],
        text: params[:reason_text],
        locale: listing.seller.locale
      )

      if reason.blank?
        redirect_to admin_listing_path(listing), alert: t("admin.listings.flash.reason_required")
        return
      end

      moderation = Listings::Moderate.new(
        listing: listing, moderator: current_user, reason: reason
      ).reject!

      if moderation
        audit!(action: "listing.rejected", auditable: listing, changes: { reason: reason })
        redirect_to admin_listing_path(listing), notice: t("admin.listings.flash.rejected")
      else
        redirect_to admin_listing_path(listing), alert: t("admin.listings.flash.already_moderated")
      end
    end
  end
end
