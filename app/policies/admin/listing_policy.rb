# frozen_string_literal: true

module Admin
  class ListingPolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def edit?
      staff?
    end

    def update?
      staff?
    end

    def destroy?
      admin?
    end

    def approve?
      staff?
    end

    def moderate?
      staff?
    end

    def reject?
      staff?
    end

    def archive?
      staff?
    end

    def restore?
      staff?
    end

    def feature?
      admin?
    end

    def label?
      admin?
    end

    def bulk?
      staff?
    end

    def export?
      staff?
    end
  end
end
