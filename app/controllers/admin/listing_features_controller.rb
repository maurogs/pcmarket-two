# frozen_string_literal: true

module Admin
  class ListingFeaturesController < BaseController
    def create
      listing = Listing.friendly.find(params[:listing_id])
      authorize listing, :feature?, policy_class: Admin::ListingPolicy

      featured_until = feature_until

      if featured_until.blank?
        redirect_to admin_listing_path(listing), alert: t("admin.listings.flash.invalid_feature_date")
        return
      end

      listing.update_columns(featured_until: featured_until, updated_at: Time.current)
      audit!(action: "listing.featured", auditable: listing,
             changes: { featured_until: featured_until.iso8601 })
      redirect_to admin_listing_path(listing), notice: t("admin.listings.flash.featured")
    end

    private

    def feature_until
      if params[:featured_until].present?
        Time.zone.parse(params[:featured_until].to_s)
      else
        days = params[:days].to_i
        days.positive? ? days.days.from_now : nil
      end
    end
  end
end
