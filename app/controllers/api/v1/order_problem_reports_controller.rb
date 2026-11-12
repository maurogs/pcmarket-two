# frozen_string_literal: true

module Api
  module V1
    class OrderProblemReportsController < AuthenticatedController
      def create
        order = current_user.orders.find(params[:order_id])
        authorize order, :report_problem?

        Orders::ReportProblem.new(
          order: order,
          actor: current_user,
          reason: params[:reason],
          details: params[:details]
        ).call

        render_data({ order_id: order.id, reported: true }, status: :accepted)
      end
    end
  end
end
