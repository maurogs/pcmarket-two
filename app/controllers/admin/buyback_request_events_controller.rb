# frozen_string_literal: true

module Admin
  class BuybackRequestEventsController < AdminOnlyController
    before_action -> { require_feature!(:sell_to_us) }
    def create
      request = BuybackRequest.find(params[:buyback_request_id])
      authorize request, :update?, policy_class: Admin::BuybackRequestPolicy

      event = params[:event].to_s
      previous_status = request.status
      advanced = Buyback::Advance.new(
        request: request,
        event: event,
        attributes: event_params
      ).call

      if advanced
        audit!(action: "buyback_request.#{event}", auditable: request,
               changes: { status: [ previous_status, request.status ],
                          revised_offer_cents: request.revised_offer_cents,
                          tracking_number: request.tracking_number })
        redirect_to admin_buyback_request_path(request),
                    notice: t("admin.buyback_requests.flash.advanced",
                              status: t("buyback.statuses.#{request.status}"))
      else
        redirect_to admin_buyback_request_path(request),
                    alert: t("admin.buyback_requests.flash.invalid_transition")
      end
    end

    private

    def event_params
      params.permit(:carrier, :tracking_number, :inspection_result, :revised_offer).to_h
    end
  end
end
