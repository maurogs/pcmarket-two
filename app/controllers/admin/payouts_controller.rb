# frozen_string_literal: true

module Admin
  class PayoutsController < BaseController
    def index
      authorize Payout, :index?, policy_class: Admin::PayoutPolicy

      @query = Admin::PayoutQuery.new(params: params)

      respond_to do |format|
        format.html
        format.csv do
          send_data export_csv, filename: "payouts-#{Date.current}.csv",
                                type: "text/csv"
        end
      end
    end

    private

    def export_csv
      Admin::CsvExport.new(
        headers: [
          t("admin.payouts.csv.id"), t("admin.payouts.csv.order"),
          t("admin.payouts.csv.store"), t("admin.payouts.csv.amount"),
          t("admin.payouts.csv.status"), t("admin.payouts.csv.transfer"),
          t("admin.payouts.csv.created_at")
        ],
        rows: Admin::PayoutQuery.new(params: params).export_records.map do |payout|
          [
            payout.id, payout.order&.number, payout.store&.name,
            payout.amount_cents / 100.0, payout.status,
            payout.stripe_transfer_id, payout.created_at.iso8601
          ]
        end
      ).to_csv
    end
  end
end
