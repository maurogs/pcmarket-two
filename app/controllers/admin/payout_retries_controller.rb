# frozen_string_literal: true

module Admin
  class PayoutRetriesController < BaseController
    def create
      payout = Payout.find(params[:payout_id])
      authorize payout, :retry?, policy_class: Admin::PayoutPolicy

      if Payouts::TransferToSeller.new(order: payout.order).call
        audit!(action: "payout.retried", auditable: payout)
        redirect_to admin_payouts_path, notice: t("admin.payouts.flash.retried")
      else
        redirect_to admin_payouts_path, alert: t("admin.payouts.flash.retry_failed")
      end
    end
  end
end
