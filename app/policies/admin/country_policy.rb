# frozen_string_literal: true

module Admin
  class CountryPolicy < ApplicationPolicy
    def index? = admin?
    def edit? = admin?
    def update? = admin?
  end
end
