# frozen_string_literal: true

module Admin
  class BuybackRequestsController < AdminOnlyController
    before_action -> { require_feature!(:sell_to_us) }
    def index
      authorize BuybackRequest, :index?, policy_class: Admin::BuybackRequestPolicy

      scope = BuybackRequest.includes(:user).recent
      scope = scope.where(status: params[:status]) if BuybackRequest::STATUSES.include?(params[:status].to_s)
      @requests = scope
      @status = params[:status].to_s
    end

    def show
      @request = BuybackRequest.includes(:user, :buyback_quote).find(params[:id])
      authorize @request, policy_class: Admin::BuybackRequestPolicy
    end
  end
end
