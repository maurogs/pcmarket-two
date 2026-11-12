# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  def create?
    return false if user.blank? || !Flipper.enabled?(:offers)

    record.listing.allow_offers? &&
      record.listing.publicly_visible? &&
      record.listing.user_id != user.id
  end

  def update?
    return false if user.blank? || !Flipper.enabled?(:offers)

    record.conversation.participant?(user) &&
      !Block.between?(user, record.conversation.other_party_for(user))
  end
end
