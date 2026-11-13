# frozen_string_literal: true

module Admin
  class LegalPagePolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def create? = admin?
    def update? = admin?
    def create_version? = admin?
    def publish? = admin?
    def compare? = admin?
    def notify? = admin?
  end
end
