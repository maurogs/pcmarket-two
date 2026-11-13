# frozen_string_literal: true

module Admin
  class StoreVerificationsController < BaseController
    def create
      store = Store.friendly.find(params[:store_id])
      authorize store, :verify?, policy_class: Admin::StorePolicy

      store.update!(verified_at: Time.current)
      audit!(action: "store.verified", auditable: store)
      redirect_to admin_store_path(store), notice: t("admin.stores.flash.verified")
    end

    def destroy
      store = Store.friendly.find(params[:store_id])
      authorize store, :unverify?, policy_class: Admin::StorePolicy

      store.update!(verified_at: nil)
      audit!(action: "store.unverified", auditable: store)
      redirect_to admin_store_path(store), notice: t("admin.stores.flash.unverified")
    end
  end
end
