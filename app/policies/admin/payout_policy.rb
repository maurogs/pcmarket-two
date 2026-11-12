# frozen_string_literal: true

module Admin
  class PayoutPolicy < ApplicationPolicy
    def index?
      admin?
    end

    def show?
      admin?
    end

    def retry?
      admin?
    end
  end
end
