# frozen_string_literal: true

module Admin
  class BuybackPricesController < AdminOnlyController
    before_action -> { require_feature!(:sell_to_us) }
    before_action :set_price, only: %i[edit update destroy]

    def index
      authorize BuybackPrice, :index?, policy_class: Admin::BuybackPricePolicy
      @prices = BuybackPrice.ordered
    end

    def new
      @price = BuybackPrice.new(active: true, base_offer_cents: 10_000,
                                condition_multipliers: default_multipliers)
      authorize @price, policy_class: Admin::BuybackPricePolicy
    end

    def create
      @price = BuybackPrice.new(price_params)
      authorize @price, policy_class: Admin::BuybackPricePolicy

      if @price.save
        audit!(action: "buyback_price.created", auditable: @price, changes: @price.saved_changes)
        redirect_to admin_buyback_prices_path, notice: t("admin.buyback_prices.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @price, policy_class: Admin::BuybackPricePolicy
    end

    def update
      authorize @price, policy_class: Admin::BuybackPricePolicy

      if @price.update(price_params)
        audit!(action: "buyback_price.updated", auditable: @price,
               changes: @price.saved_changes.except("updated_at"))
        redirect_to admin_buyback_prices_path, notice: t("admin.buyback_prices.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @price, policy_class: Admin::BuybackPricePolicy

      if @price.buyback_quotes.exists?
        redirect_to admin_buyback_prices_path, alert: t("admin.buyback_prices.flash.in_use")
        return
      end

      @price.destroy!
      audit!(action: "buyback_price.destroyed", auditable: @price)
      redirect_to admin_buyback_prices_path, notice: t("admin.buyback_prices.flash.destroyed")
    end

    private

    def set_price
      @price = BuybackPrice.find(params[:id])
    end

    def price_params
      permitted = params.require(:buyback_price).permit(:component_type, :component_model,
                                                        :base_offer_cents, :active,
                                                        condition_multipliers: {})
      permitted[:condition_multipliers] = (permitted[:condition_multipliers] || {})
                                            .to_h
                                            .slice(*BuybackPrice::CONDITION_KEYS)
                                            .transform_values(&:to_f)
      permitted
    end

    def default_multipliers
      { "like_new" => 1.0, "good" => 0.85, "fair" => 0.7, "for_parts" => 0.25 }
    end
  end
end
