# frozen_string_literal: true

module Sell
  class ListingRepublishesController < ApplicationController
    before_action :authenticate_user!

    def create
      @listing = Listing.friendly.find(params[:sell_listing_id])
      authorize @listing, :republish?

      if @listing.may_republish?
        @listing.republish!
        redirect_to sell_listings_path, notice: republished_notice
      else
        redirect_to sell_listings_path,
                    alert: t("sell.listings.flash.cannot_republish")
      end
    end

    private

    def republished_notice
      @listing.published? ? t("sell.flash.published") : t("sell.flash.submitted")
    end
  end
end
