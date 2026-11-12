# frozen_string_literal: true

class CartItemPolicy < ApplicationPolicy
  def create?
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
    cart = record.is_a?(CartItem) ? record.cart : record
    return true if cart.user_id.nil?

    user.present? && cart.user_id == user.id
  end
end
