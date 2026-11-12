# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false if user.blank? || !record.participant?(user)

    !Block.between?(user, record.other_party_for(user))
  end

  def create?
    user.present? && !user.banned? && !user.soft_deleted?
  end
end
