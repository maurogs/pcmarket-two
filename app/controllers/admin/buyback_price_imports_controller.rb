# frozen_string_literal: true

module Admin
  class BuybackPriceImportsController < AdminOnlyController
    before_action -> { require_feature!(:sell_to_us) }
    def create
      authorize BuybackPrice, :create?, policy_class: Admin::BuybackPricePolicy

      text = params[:file].respond_to?(:read) ? params[:file].read : params[:text]
      result = BuybackPrices::Import.new(text: text).call
      if result.sample
        audit!(action: "buyback_price.imported", auditable: result.sample,
               changes: { created: result.created, updated: result.updated,
                          skipped: result.skipped })
      end
      redirect_to admin_buyback_prices_path,
                  notice: t("admin.buyback_prices.flash.imported", created: result.created,
                                                                  updated: result.updated,
                                                                  skipped: result.skipped)
    end
  end
end
