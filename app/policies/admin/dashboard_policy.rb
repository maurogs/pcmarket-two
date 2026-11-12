# frozen_string_literal: true

module Admin
  class DashboardPolicy < ApplicationPolicy
    def show?
      staff?
    end
  end
end
