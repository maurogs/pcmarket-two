# frozen_string_literal: true

class OrderProblemReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    order = Order.find(params[:order_id])
    authorize order, :report_problem?

    redirect_to order_path(order), notice: t("orders.flash.problem_report_placeholder")
  end
end
