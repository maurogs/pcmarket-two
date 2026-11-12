# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    buyer? || seller? || staff?
  end

  def confirm_delivery?
    buyer? && record.may_confirm_delivery?
  end

  def cancel?
    (buyer? || seller?) && record.cancellable?
  end

  def report_problem?
    buyer?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      scope.where(buyer_id: user.id)
    end
  end

  private

  def buyer?
    user.present? && record.buyer_id == user.id
  end

  def seller?
    user.present? && record.store.present? && record.store.user_id == user.id
  end

  def staff?
    user.present? && (user.admin? || user.moderator?)
  end
end
