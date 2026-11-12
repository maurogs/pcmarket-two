# frozen_string_literal: true

module Stores
  # Updates vacation mode and schedules the automatic switch-off on the return
  # date. The job re-checks the stored date, so changing it later is safe.
  class SetVacation
    def initialize(store:, attributes:)
      @store = store
      @attributes = attributes
    end

    def call
      return false unless @store.update(@attributes)

      schedule_auto_off
      true
    end

    private

    def schedule_auto_off
      return unless @store.vacation_mode?
      return if @store.vacation_until.blank?

      Stores::VacationAutoOffJob
        .set(wait_until: @store.vacation_until.end_of_day)
        .perform_later(@store.id, @store.vacation_until)
    end
  end
end
