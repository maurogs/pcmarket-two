# frozen_string_literal: true

module Admin
  # Filters and paginates the DSA report queue, oldest first.
  class ReportQueue
    PER_PAGE = 20
    FILTERABLE_TYPES = Report::REPORTABLE_TYPES
    FILTERABLE_STATUSES = Report::STATUSES
    FILTERABLE_REASONS = Report::REASONS

    def initialize(params:)
      raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @params = raw.deep_stringify_keys
    end

    def call
      self
    end

    def reports
      @reports ||= relation.offset(pagy.offset).limit(pagy.limit).to_a
    end

    def pagy
      @pagy ||= begin
        total = relation.count
        last_page = [ (total.to_f / PER_PAGE).ceil, 1 ].max
        Pagy.new(count: total, page: [ page, last_page ].min, limit: PER_PAGE)
      end
    end

    def filters
      {
        status: normalized(:status, FILTERABLE_STATUSES),
        reason: normalized(:reason, FILTERABLE_REASONS),
        type: normalized(:type, FILTERABLE_TYPES)
      }
    end

    private

    def relation
      scope = Report.includes(:reporter, :handled_by, :reportable).oldest_first
      scope = scope.where(status: filters[:status]) if filters[:status].present?
      scope = scope.where(reason: filters[:reason]) if filters[:reason].present?
      scope = scope.where(reportable_type: filters[:type]) if filters[:type].present?
      scope
    end

    def normalized(key, allowed)
      value = @params[key].to_s
      allowed.include?(value) ? value : nil
    end

    def page
      value = Integer(@params["page"].to_s, exception: false)
      value && value.positive? ? value : 1
    end
  end
end
