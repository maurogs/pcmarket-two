# frozen_string_literal: true

require "test_helper"

class NotificationsHooksTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @listing = listings(:published_gpu)
    clear_enqueued_jobs
    clear_enqueued_jobs
  end

  def paid_order(listing: @listing)
    cart = build_cart(user: @buyer, listings: [ listing ])
    result = Checkouts::Start.new(
      cart: cart,
      buyer: @buyer,
      params: checkout_params(fulfilment: { @store.id.to_s => "shipping" }),
      gateway: Payments::FakeGateway.new
    ).call
    assert result.success?
    Checkouts::Complete.new(checkout: result.checkout, cart: cart).call
    clear_enqueued_jobs
    clear_enqueued_jobs
    result.checkout.orders.first
  end

  test "moderation records listing_approved and listing_rejected" do
    approved = listings(:pending_gpu)
    Listings::Moderate.new(listing: approved, moderator: users(:admin)).approve!

    notification = Notification.find_by(recipient: @seller, kind: "listing_approved")
    assert_equal approved, notification.notifiable
    assert_equal approved.title, notification.params["title"]

    rejected = listings(:pending_nvidia_gpu)
    Listings::Moderate.new(listing: rejected, moderator: users(:admin),
                           reason: "Photos are not clear").reject!

    notification = Notification.find_by(recipient: @seller, kind: "listing_rejected")
    assert_equal rejected, notification.notifiable
    assert_equal "Photos are not clear", notification.params["reason"]
  end

  test "completing a checkout records new_sale for the seller" do
    order = paid_order

    notification = Notification.find_by(recipient: @seller, kind: "new_sale")
    assert notification.present?
    assert_equal order, notification.notifiable
    assert_equal order.number, notification.params["number"]
    assert_equal order.total_cents, notification.params["total_cents"]
  end

  test "shipping notifies the buyer" do
    order = paid_order
    assert Orders::Ship.new(order: order, actor: @seller,
                            carrier: "seur", tracking_number: "SEUR123").call

    notification = Notification.find_by(recipient: @buyer, kind: "order_shipped")
    assert notification.present?
    assert_equal order, notification.notifiable
    assert_equal order.number, notification.params["number"]
  end

  test "confirming delivery notifies the seller" do
    order = paid_order
    Orders::Ship.new(order: order, actor: @seller, carrier: "seur",
                     tracking_number: "SEUR123").call
    assert Orders::ConfirmDelivery.new(order: order, actor: @buyer).call

    notification = Notification.find_by(recipient: @seller, kind: "order_delivered")
    assert notification.present?
    assert_equal order, notification.notifiable
  end

  test "a buyer cancellation notifies the seller" do
    order = paid_order
    assert Orders::Cancel.new(order: order, actor: @buyer,
                              gateway: Payments::FakeGateway.new).call

    assert Notification.exists?(recipient: @seller, kind: "order_cancelled",
                                notifiable: order)
  end

  test "a seller cancellation notifies the buyer" do
    order = paid_order
    assert Orders::Cancel.new(order: order, actor: @seller,
                              gateway: Payments::FakeGateway.new).call

    assert Notification.exists?(recipient: @buyer, kind: "order_cancelled",
                                notifiable: order)
  end

  test "the alert kinds used by the background jobs exist" do
    assert_includes Notification::KINDS, "price_drop"
    assert_includes Notification::KINDS, "followed_store_new_listing"
    assert_includes Notification::KINDS, "saved_search_match"
  end

  test "in-app preferences suppress hook notifications" do
    NotificationPreference.create!(user: @seller, kind: "listing_approved",
                                   in_app: false, email: true)
    NotificationPreference.create!(user: @seller, kind: "new_sale",
                                   in_app: false, email: true)

    pending = listings(:pending_gpu)
    Listings::Moderate.new(listing: pending, moderator: users(:admin)).approve!
    assert_not Notification.exists?(recipient: @seller, kind: "listing_approved")

    paid_order
    assert_not Notification.exists?(recipient: @seller, kind: "new_sale")
  end
end
