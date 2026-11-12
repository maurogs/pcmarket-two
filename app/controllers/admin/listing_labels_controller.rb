# frozen_string_literal: true

module Admin
  class ListingLabelsController < BaseController
    def create
      listing = Listing.friendly.find(params[:listing_id])
      authorize listing, :label?, policy_class: Admin::ListingPolicy

      labels = Tag.product_labels.active.where(id: Array(params[:product_label_ids])).pluck(:id)
      listing.product_label_ids = labels
      listing.save(validate: false)

      audit!(action: "listing.labelled", auditable: listing,
             changes: { product_label_ids: labels })
      redirect_to admin_listing_path(listing), notice: t("admin.listings.flash.labels_updated")
    end
  end
end
