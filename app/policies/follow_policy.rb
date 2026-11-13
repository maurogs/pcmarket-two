# frozen_string_literal: true

class FollowPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user.present? && record.follower_id == user.id
  end
end
