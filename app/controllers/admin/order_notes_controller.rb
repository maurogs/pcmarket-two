# frozen_string_literal: true

module Admin
  class OrderNotesController < BaseController
    def create
      order = Order.find(params[:order_id])
      authorize order, :note?, policy_class: Admin::OrderPolicy

      note = order.notes.new(body: params[:body], author: current_user)

      if note.save
        audit!(action: "order.note_added", auditable: order, changes: { note_id: note.id })
        redirect_to admin_order_path(order), notice: t("admin.orders.flash.note_added")
      else
        redirect_to admin_order_path(order), alert: t("admin.orders.flash.note_failed")
      end
    end
  end
end
