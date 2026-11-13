# frozen_string_literal: true

module Admin
  class OrdersController < BaseController
    before_action :set_order, only: :show

    def index
      authorize Order, :index?, policy_class: Admin::OrderPolicy

      @query = Admin::OrderQuery.new(params: params)

      respond_to do |format|
        format.html
        format.csv do
          send_data export_csv, filename: "orders-#{Date.current}.csv",
                                type: "text/csv"
        end
      end
    end

    def show
      authorize @order, policy_class: Admin::OrderPolicy

      @events = @order.events.includes(:actor).chronological
      @items = @order.items.includes(:listing)
      @notes = @order.notes.includes(:author).newest_first
      @payout = @order.payout
      @conversations = Conversation.where(id: conversation_ids).includes(:buyer, :seller)
    end

    private

    def set_order
      @order = Order.includes(:buyer, :store, :checkout, :review).find(params[:id])
    end

    def conversation_ids
      listing_ids = @order.items.pluck(:listing_id)
      Conversation.where(listing_id: listing_ids, buyer_id: @order.buyer_id).select(:id)
    end

    def export_csv
      Admin::CsvExport.new(
        headers: [
          t("admin.orders.csv.number"), t("admin.orders.csv.status"),
          t("admin.orders.csv.buyer"), t("admin.orders.csv.store"),
          t("admin.orders.csv.subtotal"), t("admin.orders.csv.shipping"),
          t("admin.orders.csv.commission"), t("admin.orders.csv.total"),
          t("admin.orders.csv.currency"), t("admin.orders.csv.created_at")
        ],
        rows: Admin::OrderQuery.new(params: params).export_records.map do |order|
          [
            order.number, order.status, order.buyer&.display_name, order.store&.name,
            cents(order.subtotal_cents), cents(order.shipping_cents),
            cents(order.commission_cents), cents(order.total_cents),
            order.currency, order.created_at.iso8601
          ]
        end
      ).to_csv
    end

    def cents(value)
      value.to_i / 100.0
    end
  end
end
