# frozen_string_literal: true

module Api
  module V1
    class ReportsController < AuthenticatedController
      def create
        authorize Report

        result = Reports::Submit.new(
          reportable_type: params[:reportable_type],
          reportable_id: params[:reportable_id],
          reporter: current_user,
          reason: params[:reason],
          details: params[:details]
        ).call

        unless result.success?
          raise Api::V1::Error.validation_failed(details: { base: result.errors })
        end

        report = result.report
        render_data({
          id: report.id,
          status: report.status,
          reason: report.reason,
          reportable_type: report.reportable_type,
          reportable_id: report.reportable_id,
          created_at: report.created_at
        }, status: :created)
      end
    end
  end
end
