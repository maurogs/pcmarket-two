# frozen_string_literal: true

module Sell
  class BulkArchivesController < ApplicationController
    before_action :authenticate_user!

    def create
      count = Sell::BulkArchive.new(user: current_user, ids: listing_ids).call

      if count.positive?
        redirect_to sell_listings_path(tab: tab_param),
                    notice: t("sell.listings.bulk.archived", count: count)
      else
        redirect_to sell_listings_path(tab: tab_param),
                    alert: t("sell.listings.bulk.nothing_selected")
      end
    end

    private

    def listing_ids
      params.dig(:bulk_archive, :listing_ids)
    end

    def tab_param
      value = params[:tab].to_s
      Sell::ListingCollection::TABS.include?(value) ? value : nil
    end
  end
end
