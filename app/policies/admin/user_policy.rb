# frozen_string_literal: true

module Admin
  # Placeholder policy for the future user administration screen.
  class UserPolicy < ApplicationPolicy
    def index?
      admin?
    end

    def show?
      admin?
    end

    def update?
      admin?
    end
  end
end
