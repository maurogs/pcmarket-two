# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def update?
    recipient?
  end

  def destroy?
    recipient?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(recipient: user)
    end
  end

  private

  def recipient?
    user.present? && record.recipient_id == user.id
  end
end
