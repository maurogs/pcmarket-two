# frozen_string_literal: true

module Admin
  class StoreSuspensionsController < BaseController
    def create
      store = Store.friendly.find(params[:store_id])
      authorize store, :suspend?, policy_class: Admin::StorePolicy

      if Admin::SuspendStore.new(store: store, actor: current_user, reason: params[:reason]).call
        audit!(action: "store.suspended", auditable: store, changes: { reason: params[:reason] })
        redirect_to admin_store_path(store), notice: t("admin.stores.flash.suspended")
      else
        redirect_to admin_store_path(store), alert: t("admin.stores.flash.reason_required")
      end
    end

    def destroy
      store = Store.friendly.find(params[:store_id])
      authorize store, :reactivate?, policy_class: Admin::StorePolicy

      store.update!(status: "active")
      audit!(action: "store.reactivated", auditable: store)
      redirect_to admin_store_path(store), notice: t("admin.stores.flash.reactivated")
    end
  end
end
