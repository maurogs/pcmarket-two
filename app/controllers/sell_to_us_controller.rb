# frozen_string_literal: true

class SellToUsController < ApplicationController
  before_action :require_sell_to_us

  def show
    authorize :sell_to_us, :show?

    prices = BuybackPrice.active.ordered.to_a
    @gpu_prices = prices.select(&:gpu?)
    @cpu_prices = prices.select(&:cpu?)
  end

  private

  def require_sell_to_us
    require_feature!(:sell_to_us)
  end
end
