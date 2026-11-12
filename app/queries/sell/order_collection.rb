# frozen_string_literal: true

module Sell
  # Seller-side order list with status filters.
  class OrderCollection
    TABS = (%w[all] + Order::STATUSES).freeze

    attr_reader :tab, :orders

    def initialize(user:, params:)
      @store = user.store
      @tab = TABS.include?(params[:status].to_s) ? params[:status].to_s : "all"
    end

    def call
      relation = @store.orders.includes(:buyer, items: :listing)
      relation = relation.where(status: @tab) unless @tab == "all"
      @orders = relation.recent_first
      self
    end
  end
end
