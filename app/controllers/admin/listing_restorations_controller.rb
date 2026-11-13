# frozen_string_literal: true

module Admin
  class ListingRestorationsController < BaseController
    def create
      listing = Listing.friendly.find(params[:listing_id])
      authorize listing, :restore?, policy_class: Admin::ListingPolicy

      unless listing.may_republish?
        redirect_to admin_listing_path(listing), alert: t("admin.listings.flash.cannot_restore")
        return
      end

      listing.republish!
      listing.moderations.create!(moderator: current_user, action: :restored)
      audit!(action: "listing.restored", auditable: listing)
      redirect_to admin_listing_path(listing), notice: t("admin.listings.flash.restored")
    end
  end
end
