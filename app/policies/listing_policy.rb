# frozen_string_literal: true

class ListingPolicy < ApplicationPolicy
  def create?
    return false if user.blank? || !user.confirmed? || user.banned? || user.soft_deleted?

    store = user.store
    store.present? && !store.suspended?
  end

  def new?
    create?
  end

  def update?
    owner?
  end

  def edit?
    update?
  end

  def destroy?
    owner?
  end

  # Republishing is a state transition on a listing the user already owns.
  def republish?
    update?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
