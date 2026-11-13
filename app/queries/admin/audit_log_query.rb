# frozen_string_literal: true

module Admin
  # Audit trail filtered by actor, auditable type and date.
  class AuditLogQuery
    include Filterable

    AUDITABLE_TYPES = %w[Listing Store User Order Review Payout AdminAuditLog].freeze

    def filters
      {
        actor_id: integer_param(:actor_id),
        auditable_type: enum_param(:auditable_type, AUDITABLE_TYPES),
        action: enum_param(:action, AuditLogQuery.actions),
        date_from: date_param(:date_from),
        date_to: date_param(:date_to)
      }
    end

    def self.actions
      %w[
        listing.approved listing.rejected listing.archived listing.restored
        listing.updated listing.destroyed listing.featured listing.labelled
        listing.bulk
        user.updated user.role_changed user.banned user.unbanned user.confirmed
        user.confirmation_resent user.password_reset_requested user.deleted
        store.updated store.verified store.unverified store.suspended
        store.reactivated review.hidden review.unhidden
        order.updated order.shipped order.delivered order.completed
        order.cancelled order.refunded order.partial_refunded order.dispute_resolved
        order.note_added payout.retried
        impersonation.started impersonation.stopped
      ].freeze
    end

    def relation
      @relation ||= apply_filters(AdminAuditLog.includes(:actor, :auditable))
    end

    def sort_options
      { "created_at" => "admin_audit_logs.created_at" }
    end

    def default_sort
      "created_at"
    end

    def actors
      @actors ||= User.where(id: AdminAuditLog.distinct.select(:actor_id)).order(:username).to_a
    end

    private

    def apply_filters(scope)
      scope = scope.where(actor_id: filters[:actor_id]) if filters[:actor_id]
      scope = scope.where(auditable_type: filters[:auditable_type]) if filters[:auditable_type]
      scope = scope.where(action: filters[:action]) if filters[:action]
      filter_by_dates(scope)
    end

    def filter_by_dates(scope)
      from = filters[:date_from]
      to = filters[:date_to]
      return scope if from.nil? && to.nil?

      scope.where(created_at: (from || Date.new(1970, 1, 1))..(to || Date.current))
    end
  end
end
