# frozen_string_literal: true

module Admin
  class AuditLogPolicy < ApplicationPolicy
    def index?
      admin?
    end
  end
end
