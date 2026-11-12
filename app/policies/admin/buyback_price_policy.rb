# frozen_string_literal: true

module Admin
  class BuybackPricePolicy < ApplicationPolicy
    def index? = admin?
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
  end
end
