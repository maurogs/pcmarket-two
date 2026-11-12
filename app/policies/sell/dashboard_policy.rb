# frozen_string_literal: true

module Sell
  class DashboardPolicy < ApplicationPolicy
    def show?
      user.present? && user.store.present?
    end
  end
end
