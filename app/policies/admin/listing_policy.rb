# frozen_string_literal: true

module Admin
  class ListingPolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def update?
      staff?
    end

    # Moderators are allowed to approve or reject pending listings.
    def moderate?
      staff?
    end
  end
end
