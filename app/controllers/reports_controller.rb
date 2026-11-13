# frozen_string_literal: true

class ReportsController < ApplicationController
  def new
    @report = Report.new(
      reportable_type: params[:reportable_type],
      reportable_id: params[:reportable_id]
    )
    authorize @report
    @reportable = find_reportable
  end

  def create
    authorize Report

    result = Reports::Submit.new(
      reportable_type: report_params[:reportable_type],
      reportable_id: report_params[:reportable_id],
      reporter: current_user,
      reporter_email: report_params[:reporter_email],
      reason: report_params[:reason],
      details: report_params[:details]
    ).call

    if result.success?
      redirect_to root_path, notice: t("reports.flash.created")
    else
      @report = result.report || Report.new(report_params)
      @reportable = find_reportable(report_params[:reportable_type], report_params[:reportable_id])
      flash.now[:alert] = result.errors.first
      render :new, status: :unprocessable_entity
    end
  end

  private

  def report_params
    params.require(:report).permit(
      :reportable_type,
      :reportable_id,
      :reporter_email,
      :reason,
      :details
    )
  end

  def find_reportable(type = params[:reportable_type], id = params[:reportable_id])
    return unless Report::REPORTABLE_TYPES.include?(type.to_s)

    type.constantize.find_by(id: id)
  end
end
