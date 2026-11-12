# frozen_string_literal: true

module Admin
  class ReportPolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def update?
      staff?
    end
  end
end
