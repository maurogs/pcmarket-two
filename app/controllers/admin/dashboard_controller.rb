# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      authorize :dashboard, :show?, policy_class: Admin::DashboardPolicy

      @stats = Admin::DashboardStats.call
      @pending_listings = Admin::ModerationQueue.oldest_pending(limit: 10)
    end
  end
end
