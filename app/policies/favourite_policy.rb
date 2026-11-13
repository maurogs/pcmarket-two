# frozen_string_literal: true

class FavouritePolicy < ApplicationPolicy
  def create?
    user.present? && record.listing.present? && record.listing.publicly_visible?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
