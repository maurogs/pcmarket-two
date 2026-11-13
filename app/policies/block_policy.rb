# frozen_string_literal: true

class BlockPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    user.present? && record.blocker_id == user.id
  end
end
