# frozen_string_literal: true

module Admin
  class ReportsController < BaseController
    before_action :set_report, only: %i[show update]

    def index
      authorize Report, policy_class: Admin::ReportPolicy
      @queue = Admin::ReportQueue.new(params: params).call
    end

    def show
      authorize @report, policy_class: Admin::ReportPolicy
      @history = Report.where(reportable: @report.reportable)
                       .where.not(id: @report.id)
                       .includes(:reporter, :handled_by)
                       .oldest_first
    end

    def update
      authorize @report, policy_class: Admin::ReportPolicy

      resolved = Admin::ResolveReport.new(
        report: @report,
        actor: current_user,
        decision: params[:decision],
        note: params[:resolution_note]
      ).call

      if resolved
        redirect_to admin_report_path(@report), notice: t("admin.reports.notices.resolved")
      else
        redirect_to admin_report_path(@report), alert: t("admin.reports.notices.invalid")
      end
    end

    private

    def set_report
      @report = Report.includes(:reporter, :handled_by, :reportable).find(params[:id])
    end
  end
end
