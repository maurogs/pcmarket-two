# frozen_string_literal: true

module Sell
  class ListingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_store
    before_action :set_listing, only: %i[edit update destroy]

    def index
      @collection = Sell::ListingCollection.new(user: current_user, params: params).call
    end

    def new
      @listing = build_listing
      authorize @listing
      @step = "category"
      prepare_step
    end

    def create
      @listing = build_listing
      authorize @listing
      @step = "category"

      if save_step(attributes: listing_params)
        redirect_to edit_sell_listing_path(@listing, step: "photos"),
                    notice: t("sell.flash.created")
      else
        prepare_step
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @listing
      @step = normalized_step(params[:step])
      prepare_step
    end

    def update
      authorize @listing
      @step = normalized_step(params[:step])

      if submitting?
        submit_listing
      else
        save_and_continue
      end
    end

    def destroy
      authorize @listing

      if @listing.draft?
        @listing.destroy!
        redirect_to sell_listings_path(tab: "drafts"), notice: t("sell.flash.destroyed")
      else
        @listing.archive!
        redirect_to sell_listings_path(tab: "archived"), notice: t("sell.flash.archived")
      end
    end

    private

    def submit_listing
      if Listings::Submit.new(listing: @listing).call
        redirect_to listing_path(@listing), notice: submitted_notice
      else
        prepare_step
        render :edit, status: :unprocessable_entity
      end
    end

    def save_and_continue
      if save_step(attributes: listing_params)
        if @step == "review"
          redirect_to listing_path(@listing), notice: t("sell.flash.saved")
        else
          redirect_to edit_sell_listing_path(@listing, step: next_step),
                      notice: t("sell.flash.saved")
        end
      else
        prepare_step
        render :edit, status: :unprocessable_entity
      end
    end

    def save_step(attributes:)
      Listings::SaveStep.new(
        listing: @listing,
        step: @step,
        attributes: attributes,
        images: params.dig(:listing, :images),
        photo_order: params.dig(:listing, :photo_order),
        remove_photo_ids: params.dig(:listing, :remove_photo_ids)
      ).call
    end

    def submitting?
      @step == "review" && params[:commit] == "submit"
    end

    def submitted_notice
      @listing.published? ? t("sell.flash.published") : t("sell.flash.submitted")
    end

    def build_listing
      Sell::BuildListing.new(user: current_user).call
    end

    def set_listing
      @listing = Listing.friendly.find(params[:id])
    end

    def ensure_store
      return if current_user.store.present?

      redirect_to new_store_path, alert: t("sell.errors.store_required")
    end

    def prepare_step
      @attributes = @listing.category&.effective_category_attributes || []
      @seller_tags = Tag.seller_tags.active.ordered
      @regions = Region.where(country_code: "ES").order(:position, :name)
      @root_categories = Category.active.roots.includes(:children).order(:position, :id)
    end

    def normalized_step(value)
      step = value.to_s
      Listing::WIZARD_STEPS.include?(step) ? step : Listing::WIZARD_STEPS.first
    end

    def next_step
      index = Listing::WIZARD_STEPS.index(@step) || 0
      Listing::WIZARD_STEPS[[ index + 1, Listing::WIZARD_STEPS.length - 1 ].min]
    end

    def listing_params
      params.fetch(:listing, ActionController::Parameters.new).permit(
        :category_id, :title, :description, :condition,
        :price, :compare_at_price, :quantity, :allow_offers,
        :shipping_mode, :shipping_price, :free_shipping, :handling_days,
        :region_id, :city, :postal_code,
        specs: {}, seller_tag_ids: []
      )
    end
  end
end
