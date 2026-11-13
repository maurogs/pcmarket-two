# frozen_string_literal: true

module Admin
  class ListingArchivalsController < BaseController
    def create
      listing = Listing.friendly.find(params[:listing_id])
      authorize listing, :archive?, policy_class: Admin::ListingPolicy

      unless listing.may_archive?
        redirect_to admin_listing_path(listing), alert: t("admin.listings.flash.cannot_archive")
        return
      end

      begin
        listing.archive!
      rescue ActiveRecord::RecordInvalid
        listing.archive_without_validation!
      end
      listing.moderations.create!(moderator: current_user, action: :archived)
      audit!(action: "listing.archived", auditable: listing)
      redirect_to admin_listing_path(listing), notice: t("admin.listings.flash.archived")
    end
  end
end
