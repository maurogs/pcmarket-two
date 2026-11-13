# frozen_string_literal: true

class StorePolicy < ApplicationPolicy
  def create?
    user.present? &&
      user.confirmed? &&
      !user.banned? &&
      !user.soft_deleted? &&
      record.new_record? && !Store.exists?(user_id: user.id)
  end

  def new?
    create?
  end

  def update?
    user.present? && record.user_id == user.id
  end

  def edit?
    update?
  end
end
