# frozen_string_literal: true

module Admin
  # Placeholder policy for the future site-settings screen.
  class SettingPolicy < ApplicationPolicy
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
