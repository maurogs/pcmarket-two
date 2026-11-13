# frozen_string_literal: true

class AddressPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owns_address?
  end

  def create?
    user.present?
  end

  def new?
    create?
  end

  def update?
    owns_address?
  end

  def edit?
    update?
  end

  def destroy?
    owns_address?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(user_id: user.id)
    end
  end

  private

  def owns_address?
    user.present? && record.present? && record.user_id == user.id
  end
end
