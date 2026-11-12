# frozen_string_literal: true

module Admin
  class AttributeOptionPolicy < ApplicationPolicy
    def create? = admin?
    def update? = admin?
    def destroy? = admin?
    def merge? = admin?
    def import? = admin?
    def reorder? = admin?
  end
end
