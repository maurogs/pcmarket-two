# frozen_string_literal: true

module Sell
  class DashboardsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_store

    def show
      @store = current_user.store
      authorize :dashboard, :show?, policy_class: Sell::DashboardPolicy
      @range = normalized_range
      @analytics = Sell::Analytics.new(store: @store, range: @range).call
    end

    private

    def ensure_store
      return if current_user.store.present?

      redirect_to new_store_path, alert: t("sell.errors.store_required")
    end

    def normalized_range
      value = params[:range].to_i
      Sell::Analytics::RANGES.include?(value) ? value : Sell::Analytics::DEFAULT_RANGE
    end
  end
end
