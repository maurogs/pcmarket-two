# frozen_string_literal: true

module Admin
  # Persists an audit row for every staff mutation. Controllers mix this in and
  # call `audit!` after the service or model change succeeds.
  module Auditable
    extend ActiveSupport::Concern

    private

    def audit!(action:, auditable:, changes: {})
      AdminAuditLog.record!(
        actor: current_user,
        action: action,
        auditable: auditable,
        changes: changes,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
    end
  end
end
