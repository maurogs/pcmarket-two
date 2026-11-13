# frozen_string_literal: true

module Admin
  class StoresController < BaseController
    before_action :set_store, only: %i[show edit update]

    def index
      authorize Store, :index?, policy_class: Admin::StorePolicy

      @query = Admin::StoreQuery.new(params: params)

      respond_to do |format|
        format.html
        format.csv do
          send_data export_csv, filename: "stores-#{Date.current}.csv",
                                type: "text/csv"
        end
      end
    end

    def show
      authorize @store, policy_class: Admin::StorePolicy

      @listings = @store.listings.includes(:category).order(created_at: :desc).limit(20)
      @reviews = @store.reviews.includes(:reviewer, :order).newest_first.limit(20)
      @followers = @store.followers.order(:username).limit(20)
      @completed_orders = @store.orders.where(status: %w[completed delivered]).count
      @sales_total_cents = @store.orders.where(status: %w[completed delivered]).sum(:total_cents)
      @payouts = @store.payouts.order(created_at: :desc).limit(10)
    end

    def edit
      authorize @store, policy_class: Admin::StorePolicy
      @regions = Region.where(country_code: @store.country_code).order(:name)
    end

    def update
      authorize @store, policy_class: Admin::StorePolicy

      if @store.update(store_params)
        changes = @store.saved_changes.except("updated_at", "slug")
        audit!(action: "store.updated", auditable: @store, changes: changes)
        redirect_to admin_store_path(@store), notice: t("admin.stores.flash.updated")
      else
        @regions = Region.where(country_code: @store.country_code).order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_store
      @store = Store.friendly.find(params[:id])
    end

    def store_params
      params.require(:store).permit(
        :name, :description, :kind, :legal_name, :tax_id, :address_line, :city,
        :region_id, :postal_code, :country_code, :phone, :website,
        :return_policy, :shipping_policy, :handling_days, :allow_offers_default
      )
    end

    def export_csv
      Admin::CsvExport.new(
        headers: [
          t("admin.stores.csv.id"), t("admin.stores.csv.name"), t("admin.stores.csv.owner"),
          t("admin.stores.csv.kind"), t("admin.stores.csv.status"),
          t("admin.stores.csv.verified"), t("admin.stores.csv.payouts_ready"),
          t("admin.stores.csv.rating"), t("admin.stores.csv.listings"),
          t("admin.stores.csv.created_at")
        ],
        rows: Admin::StoreQuery.new(params: params).export_records.map do |store|
          [
            store.id, store.name, store.user&.display_name, store.kind, store.status,
            store.verified? ? t("admin.common.yes") : t("admin.common.no"),
            store.payouts_ready? ? t("admin.common.yes") : t("admin.common.no"),
            store.rating_average.to_s, store.listings_count, store.created_at.iso8601
          ]
        end
      ).to_csv
    end
  end
end
