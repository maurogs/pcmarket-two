# frozen_string_literal: true

module Admin
  class CategoryPolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
    def reorder? = admin?
    def manage_filters? = admin?
  end
end
