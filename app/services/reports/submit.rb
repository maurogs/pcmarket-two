# frozen_string_literal: true

module Reports
  # Validates the reported object, persists the notice and acknowledges it by
  # email. Anonymous reports carry their own contact email.
  class Submit
    Result = Struct.new(:success, :report, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(reportable_type:, reportable_id:, reporter: nil, reporter_email: nil, reason:, details:)
      @reportable_type = reportable_type.to_s
      @reportable_id = reportable_id
      @reporter = reporter
      @reporter_email = reporter_email
      @reason = reason
      @details = details
    end

    def call
      reportable = find_reportable
      return failure("reports.errors.unavailable") if reportable.nil?

      report = Report.new(
        reporter: @reporter,
        reporter_email: @reporter.present? ? nil : @reporter_email,
        reportable: reportable,
        reason: @reason,
        details: @details
      )

      if report.save
        ReportMailer.acknowledgement(report).deliver_later
        Result.new(success: true, report: report, errors: [])
      else
        Result.new(success: false, report: report, errors: report.errors.full_messages)
      end
    end

    private

    def find_reportable
      return if @reportable_type.blank? || !Report::REPORTABLE_TYPES.include?(@reportable_type)

      @reportable_type.constantize.find_by(id: @reportable_id)
    end

    def failure(key)
      Result.new(success: false, report: nil, errors: [ I18n.t(key) ])
    end
  end
end
