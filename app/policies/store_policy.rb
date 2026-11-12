# frozen_string_literal: true

class StorePolicy < ApplicationPolicy
  def create?
    user.present? &&
      user.confirmed? &&
      !user.banned? &&
      !user.soft_deleted? &&
      (user.store.nil? || user.store.new_record?)
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
