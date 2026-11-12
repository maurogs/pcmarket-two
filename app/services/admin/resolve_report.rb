# frozen_string_literal: true

module Admin
  # Applies the DSA notice-and-action decision, records the statement of
  # reasons and emails the reporter.
  class ResolveReport
    ACTIONS = %w[dismiss action].freeze

    def initialize(report:, actor:, decision:, note:)
      @report = report
      @actor = actor
      @decision = decision.to_s
      @note = note.to_s.strip
    end

    def call
      return false unless ACTIONS.include?(@decision)
      return false if @note.blank?
      return false if @report.resolved?

      Report.transaction do
        apply_action if @decision == "action"
        @report.update!(
          status: @decision == "action" ? "actioned" : "dismissed",
          resolution_note: @note,
          handled_by: @actor,
          handled_at: Time.current
        )
      end

      ReportMailer.decision(@report).deliver_later
      true
    end

    private

    def apply_action
      case @report.reportable
      when Listing
        @report.reportable.archive! if @report.reportable.may_archive?
      when User
        @report.reportable.update!(banned_at: Time.current, ban_reason: @note)
      when Message
        @report.reportable.update!(hidden_at: Time.current)
      when Store
        @report.reportable.update!(status: "suspended")
      when Review
        @report.reportable.update!(status: "hidden")
      end
    end
  end
end
