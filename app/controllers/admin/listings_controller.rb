# frozen_string_literal: true

module Admin
  class ListingsController < BaseController
    before_action :set_listing, only: %i[show edit update destroy]

    def index
      authorize Listing, :index?, policy_class: Admin::ListingPolicy

      @query = Admin::ListingQuery.new(params: params)

      respond_to do |format|
        format.html
        format.csv do
          authorize Listing, :export?, policy_class: Admin::ListingPolicy
          send_data export_csv, filename: "listings-#{Date.current}.csv",
                                type: "text/csv"
        end
      end
    end

    def show
      authorize @listing, policy_class: Admin::ListingPolicy

      @moderations = @listing.moderations.includes(:moderator).order(created_at: :desc)
      @reports = Report.where(reportable: @listing).includes(:reporter).order(created_at: :desc)
      @orders = Order.where(id: @listing.order_items.select(:order_id))
                     .includes(:buyer, :store).recent_first
      @daily_views = ListingView.where(listing_id: @listing.id).order(date: :desc).limit(30)
      @product_labels = Tag.product_labels.active.ordered
      @seller_tags = Tag.seller_tags.active.ordered
    end

    def edit
      authorize @listing, policy_class: Admin::ListingPolicy

      @attributes = @listing.category ? @listing.category.effective_category_attributes
                                               .includes(attribute_definition: :attribute_options) : []
      @seller_tags = Tag.seller_tags.active.ordered
      @product_labels = Tag.product_labels.active.ordered
      @regions = Region.where(country_code: @listing.country_code).order(:name)
      @categories = Category.active.order(:depth, :position, :id).to_a
    end

    def update
      authorize @listing, policy_class: Admin::ListingPolicy

      if @listing.update(listing_params)
        audit!(action: "listing.updated", auditable: @listing,
               changes: audit_changes)
        redirect_to admin_listing_path(@listing), notice: t("admin.listings.flash.updated")
      else
        prepare_form
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @listing, policy_class: Admin::ListingPolicy

      unless deletable?
        redirect_to admin_listing_path(@listing), alert: t("admin.listings.flash.not_deletable")
        return
      end

      @listing.destroy!
      audit!(action: "listing.destroyed", auditable: @listing)
      redirect_to admin_listings_path, notice: t("admin.listings.flash.destroyed")
    end

    private

    def set_listing
      @listing = Listing.with_detail_includes.friendly.find(params[:id])
    end

    def deletable?
      (@listing.draft? || @listing.archived?) && !@listing.order_items.exists?
    end

    def listing_params
      params.require(:listing).permit(
        :title, :description, :category_id, :condition, :price, :compare_at_price,
        :quantity, :shipping_mode, :shipping_price, :free_shipping, :handling_days,
        :allow_offers, :region_id, :city, :postal_code,
        specs: {}, seller_tag_ids: [], product_label_ids: []
      )
    end

    def prepare_form
      @attributes = @listing.category ? @listing.category.effective_category_attributes
                                               .includes(attribute_definition: :attribute_options) : []
      @seller_tags = Tag.seller_tags.active.ordered
      @product_labels = Tag.product_labels.active.ordered
      @regions = Region.where(country_code: @listing.country_code).order(:name)
      @categories = Category.active.order(:depth, :position, :id).to_a
    end

    def audit_changes
      @listing.saved_changes.except("updated_at", "searchable")
    end

    def export_csv
      Admin::CsvExport.new(
        headers: [
          t("admin.listings.csv.id"), t("admin.listings.csv.title"),
          t("admin.listings.csv.status"), t("admin.listings.csv.seller"),
          t("admin.listings.csv.store"), t("admin.listings.csv.category"),
          t("admin.listings.csv.price"), t("admin.listings.csv.views"),
          t("admin.listings.csv.favourites"), t("admin.listings.csv.created_at")
        ],
        rows: @query.export_records.map do |listing|
          [
            listing.id, listing.title, listing.status,
            listing.seller&.display_name, listing.store&.name, listing.category&.name,
            listing.price_cents ? (listing.price_cents / 100.0) : nil,
            listing.views_count, listing.favorites_count, listing.created_at.iso8601
          ]
        end
      ).to_csv
    end
  end
end
