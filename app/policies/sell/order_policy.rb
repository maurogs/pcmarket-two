# frozen_string_literal: true

module Sell
  class OrderPolicy < ApplicationPolicy
    def index?
      user.present? && user.store.present?
    end

    def show?
      return false if user.blank? || user.store.blank?

      record.store_id == user.store.id
    end

    def ship?
      show? && record.paid?
    end

    def cancel?
      show? && record.cancellable?
    end
  end
end
