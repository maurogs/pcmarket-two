# frozen_string_literal: true

class BuybackQuotesController < ApplicationController
  before_action :require_sell_to_us

  def new
    authorize :buyback_quote, :new?
    @prices = BuybackPrice.active.ordered.to_a
    @selected_type = params[:component_type].to_s == "cpu" ? "cpu" : "gpu"
  end

  def create
    authorize :buyback_quote, :create?
    @prices = BuybackPrice.active.ordered.to_a
    @selected_type = params[:component_type].to_s
    price = BuybackPrice.active.find_by(id: params[:buyback_price_id])

    if price.blank?
      @quote = BuybackQuote.new
      @quote.errors.add(:base, t("buyback.errors.price_missing"))
      render :new, status: :unprocessable_entity
      return
    end

    @quote = BuybackQuote.new(
      buyback_price: price,
      component_type: price.component_type,
      component_model: price.component_model,
      condition: params[:condition],
      answers: condition_answers,
      offer_cents: Buyback::Quote.new(price: price, condition: params[:condition],
                                      answers: condition_answers).offer_cents
    )

    if @quote.save
      redirect_to buyback_quote_path(@quote.token),
                  notice: t("buyback.flash.quote_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @quote = BuybackQuote.find_by!(token: params[:id])
    authorize @quote, :show?, policy_class: BuybackQuotePolicy
  end

  private

  def condition_answers
    params.permit(:powers_on, :artifacts, :original_box, :physical_damage)
          .to_h
          .transform_keys { |key| key.to_sym }
  end

  def require_sell_to_us
    require_feature!(:sell_to_us)
  end
end
