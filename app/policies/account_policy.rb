# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  def show?
    own_account?
  end

  def update?
    own_account?
  end

  # Deletion is confirmed by the controller (password or typed username).
  def destroy?
    own_account?
  end

  def export?
    own_account?
  end

  private

  def own_account?
    user.present? && record.present? && record.id == user.id
  end
end
