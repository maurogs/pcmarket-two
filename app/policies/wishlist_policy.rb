# frozen_string_literal: true

class WishlistPolicy < ApplicationPolicy
  def show?
    user.present?
  end
end
