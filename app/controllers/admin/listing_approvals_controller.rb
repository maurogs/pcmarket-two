# frozen_string_literal: true

module Admin
  class ListingApprovalsController < BaseController
    def create
      listing = Listing.friendly.find(params[:listing_id])
      authorize listing, :approve?, policy_class: Admin::ListingPolicy

      moderation = Listings::Moderate.new(listing: listing, moderator: current_user).approve!

      if moderation
        audit!(action: "listing.approved", auditable: listing)
        redirect_to admin_listing_path(listing), notice: t("admin.listings.flash.approved")
      else
        redirect_to admin_listing_path(listing), alert: t("admin.listings.flash.already_moderated")
      end
    end
  end
end
