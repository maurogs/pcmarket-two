# frozen_string_literal: true

module Admin
  # Staff-only audit trail. Read-only: entries are written by Admin::Auditable.
  class AuditLogsController < BaseController
    def index
      authorize AdminAuditLog, :index?, policy_class: Admin::AuditLogPolicy

      @query = Admin::AuditLogQuery.new(params: params)
    end
  end
end
