# frozen_string_literal: true

module Stores
  # Turns vacation mode off once the seller's return date has passed.
  class VacationAutoOffJob < ApplicationJob
    queue_as :default

    def perform(store_id, expected_until = nil)
      store = Store.find_by(id: store_id)
      return if store.blank? || !store.vacation_mode?
      return if expected_until.present? && store.vacation_until.to_s != expected_until.to_s
      return if store.vacation_until.blank? || store.vacation_until > Date.current

      store.update(vacation_mode: false, vacation_until: nil)
    end
  end
end
