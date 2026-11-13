# frozen_string_literal: true

require "test_helper"

class Checkouts::LifecycleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    clear_enqueued_jobs
    ActionMailer::Base.deliveries.clear
    @buyer = users(:moderator)
    @store = stores(:confirmed_store)
    @listing = listings(:published_gpu)
  end

  def start_checkout(gateway: Payments::FakeGateway.new)
    cart = build_cart(user: @buyer, listings: [ @listing ])
    result = Checkouts::Start.new(
      cart: cart,
      buyer: @buyer,
      params: checkout_params(fulfilment: { @store.id.to_s => "shipping" }),
      gateway: gateway
    ).call
    [ result.checkout, cart, result ]
  end

  test "complete pays the checkout, sells the stock, clears the cart and emails both parties" do
    checkout, cart = start_checkout
    order = checkout.orders.first

    assert Checkouts::Complete.new(checkout: checkout, cart: cart).call

    assert_equal "paid", checkout.reload.status
    assert order.reload.paid?
    assert_equal "sold", @listing.reload.status
    assert_equal 0, @listing.quantity
    assert_empty cart.items.reload

    assert_enqueued_email_with OrderMailer, :buyer_confirmation, args: [ order ]
    assert_enqueued_email_with OrderMailer, :seller_new_sale, args: [ order ]
    assert_enqueued_emails 2

    assert_not Checkouts::Complete.new(checkout: checkout, cart: cart).call
    assert_enqueued_emails 2
  end

  test "fail releases stock, cancels pending orders and emails nobody" do
    checkout, = start_checkout

    assert Checkouts::Fail.new(checkout: checkout).call

    assert_equal "failed", checkout.reload.status
    assert_equal "cancelled", checkout.orders.first.status
    assert_equal "published", @listing.reload.status
    assert_equal 1, @listing.quantity
    assert_no_enqueued_emails

    assert_not Checkouts::Fail.new(checkout: checkout).call
  end

  test "expire releases stock and the scheduled job expires stale checkouts" do
    checkout, = start_checkout
    checkout.update!(expires_at: 1.minute.ago)

    ReleaseExpiredReservationsJob.perform_now

    assert_equal "expired", checkout.reload.status
    assert_equal "cancelled", checkout.orders.first.status
    assert_equal "published", @listing.reload.status
    assert_equal 1, @listing.quantity
  end

  test "the expiry job ignores checkouts that still have time left" do
    checkout, = start_checkout

    ReleaseExpiredReservationsJob.perform_now

    assert_equal "pending", checkout.reload.status
    assert_equal "reserved", @listing.reload.status
  end

  test "confirmation emails use each recipient's locale when the job runs" do
    @buyer.update!(locale: "fr")
    users(:confirmed).update!(locale: "de")
    checkout, cart = start_checkout

    Checkouts::Complete.new(checkout: checkout, cart: cart).call
    assert_enqueued_emails 2
    perform_enqueued_jobs

    assert_equal 2, ActionMailer::Base.deliveries.size
    buyer_mail = ActionMailer::Base.deliveries.find { |mail| mail.to.include?(@buyer.email) }
    seller_mail = ActionMailer::Base.deliveries.find { |mail| mail.to.include?(users(:confirmed).email) }

    assert_equal I18n.t("order_mailer.buyer_confirmation.subject",
                        number: checkout.orders.first.number, locale: :fr),
                 buyer_mail.subject
    assert_equal I18n.t("order_mailer.seller_new_sale.subject",
                        number: checkout.orders.first.number, locale: :de),
                 seller_mail.subject
  end
end
