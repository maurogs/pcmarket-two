# frozen_string_literal: true

module Api
  module V1
    module Sell
      class AnalyticsController < AuthenticatedController
        def show
          store = current_user.store
          raise ActiveRecord::RecordNotFound if store.blank?

          authorize :dashboard, :show?, policy_class: ::Sell::DashboardPolicy
          range = normalized_range
          analytics = ::Sell::Analytics.new(store: store, range: range).call
          render_resource(analytics, AnalyticsSerializer)
        end

        private

        def normalized_range
          value = params[:range].to_i
          ::Sell::Analytics::RANGES.include?(value) ? value : ::Sell::Analytics::DEFAULT_RANGE
        end
      end
    end
  end
end
