# frozen_string_literal: true

require "test_helper"

class OrdersFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @listing = listings(:published_gpu)
  end

  def paid_order
    cart = build_cart(user: @buyer, listings: [ @listing ])
    result = Checkouts::Start.new(
      cart: cart,
      buyer: @buyer,
      params: checkout_params(fulfilment: { @store.id.to_s => "shipping" }),
      gateway: Payments::FakeGateway.new
    ).call
    assert result.success?
    Checkouts::Complete.new(checkout: result.checkout, cart: cart).call
    clear_enqueued_jobs
    result.checkout.orders.first
  end

  test "buyers see their orders list and order detail" do
    order = paid_order
    sign_in @buyer

    get orders_path(locale: :en)

    assert_response :success
    assert_includes response.body, order.number

    get order_path(order, locale: :en)

    assert_response :success
    assert_includes response.body, order.number
    assert_includes response.body, I18n.t("orders.show.timeline", locale: :en)
  end

  test "sellers see their sales, the paid buyer address and can ship" do
    order = paid_order
    sign_in @seller

    get sell_orders_path(locale: :en)

    assert_response :success
    assert_includes response.body, order.number

    get sell_order_path(order, locale: :en)

    assert_response :success
    assert_includes response.body, "Calle Mayor 1"

    post sell_order_shipment_path(order, locale: :en),
         params: { carrier: "seur", tracking_number: "SEUR123" }

    assert_redirected_to sell_order_path(order, locale: :en)
    assert order.reload.shipped?
    assert_equal "SEUR123", order.tracking_number
  end

  test "a buyer cannot open the seller sales area" do
    order = paid_order
    sign_in @buyer

    get sell_order_path(order, locale: :en)

    assert_redirected_to new_store_path(locale: :en)
  end

  test "buyers can confirm delivery after shipping" do
    order = paid_order
    Orders::Ship.new(order: order, actor: @seller, carrier: "seur",
                     tracking_number: "SEUR123").call
    sign_in @buyer

    post order_delivery_confirmation_path(order, locale: :en)

    assert_redirected_to order_path(order, locale: :en)
    assert order.reload.delivered?
    assert order.buyer_protection_ends_at.present?
  end

  test "sellers cannot confirm delivery" do
    order = paid_order
    Orders::Ship.new(order: order, actor: @seller, carrier: "seur",
                     tracking_number: "SEUR123").call
    sign_in @seller

    post order_delivery_confirmation_path(order, locale: :en)

    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
    assert order.reload.shipped?
  end

  test "buyers can cancel an unshipped order and stock is returned" do
    order = paid_order
    sign_in @buyer

    post order_cancellation_path(order, locale: :en), params: { reason: "Changed my mind" }

    assert_redirected_to order_path(order, locale: :en)
    assert order.reload.cancelled?
    assert_equal "published", @listing.reload.status
    assert_equal 1, @listing.quantity
  end

  test "guests are sent to sign in for the buyer orders area" do
    get orders_path(locale: :en)

    assert_redirected_to new_user_session_path(locale: :en)
  end
end
