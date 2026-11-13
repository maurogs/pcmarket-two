# frozen_string_literal: true

module Admin
  class StoreReviewVisibilitiesController < BaseController
    def create
      store = Store.friendly.find(params[:store_id])
      authorize store, :hide_review?, policy_class: Admin::StorePolicy

      review = store.reviews.find(params[:review_id])
      review.update!(status: "hidden")
      audit!(action: "review.hidden", auditable: review)
      redirect_to admin_store_path(store), notice: t("admin.stores.flash.review_hidden")
    end

    def destroy
      store = Store.friendly.find(params[:store_id])
      authorize store, :unhide_review?, policy_class: Admin::StorePolicy

      review = store.reviews.find(params[:review_id])
      review.update!(status: "visible")
      audit!(action: "review.unhidden", auditable: review)
      redirect_to admin_store_path(store), notice: t("admin.stores.flash.review_unhidden")
    end
  end
end
