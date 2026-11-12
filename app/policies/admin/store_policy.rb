# frozen_string_literal: true

module Admin
  class StorePolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def edit?
      admin?
    end

    def update?
      admin?
    end

    def verify?
      admin?
    end

    def unverify?
      admin?
    end

    def suspend?
      admin?
    end

    def reactivate?
      admin?
    end

    def hide_review?
      admin?
    end

    def unhide_review?
      admin?
    end

    def export?
      staff?
    end
  end
end
