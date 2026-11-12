# frozen_string_literal: true

module Admin
  class AttributeDefinitionPolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
    def manage_options? = admin?
  end
end
