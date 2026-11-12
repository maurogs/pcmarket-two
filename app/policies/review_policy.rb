# frozen_string_literal: true

class ReviewPolicy < ApplicationPolicy
  def show?
    record.visible? || owner? || staff?
  end

  def create?
    user.present? && record.order.present? &&
      record.order.buyer_id == user.id &&
      record.order.reviewable?
  end

  def update?
    user.present? && record.reviewer_id == user.id && record.editable?
  end

  # A seller may reply once per review.
  def reply?
    user.present? && record.store.user_id == user.id && !record.seller_replied?
  end

  private

  def owner?
    user.present? && record.reviewer_id == user.id
  end

  def staff?
    user.present? && (user.admin? || user.moderator?)
  end
end
