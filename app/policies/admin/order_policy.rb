# frozen_string_literal: true

module Admin
  class OrderPolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def ship?
      admin?
    end

    def deliver?
      admin?
    end

    def complete?
      admin?
    end

    def cancel?
      admin?
    end

    def refund?
      admin?
    end

    def resolve_dispute?
      admin?
    end

    def note?
      admin?
    end

    def export?
      staff?
    end
  end
end
