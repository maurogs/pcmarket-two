# frozen_string_literal: true

class CartPolicy < ApplicationPolicy
  def show?
    owns_cart?
  end

  def update?
    owns_cart?
  end

  def destroy?
    owns_cart?
  end

  private

  def owns_cart?
    return true if record.user_id.nil?

    user.present? && record.user_id == user.id
  end
end
