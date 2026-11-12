# frozen_string_literal: true

module Admin
  class RegionPolicy < ApplicationPolicy
    def index? = admin?
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
    def import? = admin?
  end
end
