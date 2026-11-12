# frozen_string_literal: true

module Admin
  class GamePolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
  end
end
