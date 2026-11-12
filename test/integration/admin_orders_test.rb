# frozen_string_literal: true

require "test_helper"

class AdminOrdersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in users(:admin)
  end

  test "moderators can read orders but cannot act on them" do
    order = create_order!

    sign_out users(:admin)
    sign_in users(:moderator)

    get admin_orders_path(locale: :en)
    assert_response :success

    get admin_order_path(order, locale: :en)
    assert_response :success

    post admin_order_shipment_path(order, locale: :en),
         params: { carrier: "seur", tracking_number: "TRACK1" }

    assert_response :redirect
    assert_equal "paid", order.reload.status
  end

  test "payouts are admin-only" do
    sign_out users(:admin)
    sign_in users(:moderator)

    get admin_payouts_path(locale: :en)

    assert_response :redirect
  end

  test "the index supports number search, status and amount filters" do
    order = create_order!(total_cents: 25_000)

    get admin_orders_path(locale: :en, q: order.number)
    assert_response :success
    assert_includes response.body, order.number

    get admin_orders_path(locale: :en, status: "paid")
    assert_includes response.body, order.number

    get admin_orders_path(locale: :en, amount_min: "300")
    assert_not_includes response.body, order.number
  end

  test "CSV export includes the filtered orders" do
    order = create_order!(total_cents: 31_000)

    get admin_orders_path(locale: :en, status: "paid", format: :csv)

    assert_response :success
    assert_includes response.body, order.number
    assert_includes response.body, "310.0"
  end

  test "shipping, delivering and completing an order on behalf of the parties" do
    order = create_order!

    post admin_order_shipment_path(order, locale: :en),
         params: { carrier: "seur", tracking_number: "TRACK123" }

    assert_redirected_to admin_order_path(order, locale: :en)
    order.reload
    assert order.shipped?
    assert_equal "TRACK123", order.tracking_number

    post admin_order_delivery_path(order, locale: :en)
    assert order.reload.delivered?
    assert order.buyer_protection_ends_at.present?

    post admin_order_completion_path(order, locale: :en)
    assert order.reload.completed?
    assert order.payout.present?
  end

  test "an order can be cancelled and refunded" do
    order = create_order!

    post admin_order_cancellation_path(order, locale: :en), params: { reason: "Out of stock" }

    assert_redirected_to admin_order_path(order, locale: :en)
    assert order.reload.cancelled?
    assert_equal "cancelled", order.events.last.event
  end

  test "a partial refund is recorded on the timeline" do
    order = create_order!(total_cents: 20_000)

    post admin_order_refund_path(order, locale: :en), params: { amount: "50.00" }

    assert_redirected_to admin_order_path(order, locale: :en)
    event = order.events.last
    assert_equal "partial_refund", event.event
    assert_equal 5000, event.data["amount_cents"]
    assert_equal "order.partial_refunded", AdminAuditLog.last.action
  end

  test "an invalid partial refund is rejected" do
    order = create_order!(total_cents: 20_000)

    post admin_order_refund_path(order, locale: :en), params: { amount: "500.00" }

    assert_redirected_to admin_order_path(order, locale: :en)
    assert_equal I18n.t("admin.orders.flash.refund_failed", locale: :en), flash[:alert]
  end

  test "a dispute can be refunded to the buyer" do
    order = create_order!
    order.open_dispute!

    post admin_order_dispute_resolution_path(order, locale: :en),
         params: { decision: "refund", note: "Item not as described" }

    assert_redirected_to admin_order_path(order, locale: :en)
    assert order.reload.refunded?
    assert_equal "order.dispute_resolved", AdminAuditLog.last.action
  end

  test "a dispute can be released to the seller" do
    order = create_order!
    order.open_dispute!

    post admin_order_dispute_resolution_path(order, locale: :en),
         params: { decision: "release" }

    assert_redirected_to admin_order_path(order, locale: :en)
    assert order.reload.completed?
    assert order.payout.present?
  end

  test "internal notes are stored and shown only to staff" do
    order = create_order!

    assert_difference "OrderNote.count", 1 do
      post admin_order_notes_path(order, locale: :en), params: { body: "Buyer called support." }
    end

    get admin_order_path(order, locale: :en)
    assert_includes response.body, "Buyer called support."
  end

  test "failed payouts can be retried" do
    order = create_order!(status: "completed", delivered_at: Time.current)
    payout = Payout.create!(order: order, store: order.store, amount_cents: 10_000,
                            status: "failed", error: "bank_error")

    post admin_payout_retry_path(payout, locale: :en)

    assert_redirected_to admin_payouts_path(locale: :en)
    assert_equal "paid", payout.reload.status
  end

  test "payouts index lists failed transfers" do
    order = create_order!(status: "completed", delivered_at: Time.current)
    Payout.create!(order: order, store: order.store, amount_cents: 10_000,
                   status: "failed", error: "bank_error")

    get admin_payouts_path(locale: :en, status: "failed")

    assert_response :success
    assert_includes response.body, order.number
  end
end
