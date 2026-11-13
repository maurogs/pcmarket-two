# frozen_string_literal: true

module Admin
  class BuybackRequestPolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def update? = admin?
  end
end
