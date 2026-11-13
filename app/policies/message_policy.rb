# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    return false if user.blank?

    conversation = record.conversation
    conversation.present? &&
      conversation.participant?(user) &&
      !Block.between?(user, conversation.other_party_for(user))
  end
end
