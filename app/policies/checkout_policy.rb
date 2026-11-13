# frozen_string_literal: true

class CheckoutPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end

  def show?
    return true if record.buyer_id.nil?

    user.present? && record.buyer_id == user.id
  end
end
