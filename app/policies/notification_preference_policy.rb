# frozen_string_literal: true

class NotificationPreferencePolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def update?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(user: user)
    end
  end
end
