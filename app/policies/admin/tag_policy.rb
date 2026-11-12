# frozen_string_literal: true

module Admin
  class TagPolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
    def reorder? = admin?
  end
end
