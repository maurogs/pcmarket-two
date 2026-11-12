# frozen_string_literal: true

module Admin
  class FeaturePolicy < ApplicationPolicy
    def index? = admin?
    def update? = admin?
  end
end
