# frozen_string_literal: true

class BuybackRequestPolicy < ApplicationPolicy
  def index? = user.present?
  def new? = user.present?
  def create? = user.present?

  def show?
    return false unless user.present?

    record.user_id == user.id || user.admin? || user.moderator?
  end
end
