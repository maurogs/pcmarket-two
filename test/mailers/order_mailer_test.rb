# frozen_string_literal: true

require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @buyer = users(:moderator)
    @buyer.update!(locale: "fr")
    @seller = users(:confirmed)
    @seller.update!(locale: "de")
    @listing = listings(:published_gpu)
    checkout = Checkout.create!(buyer: @buyer, email: @buyer.email,
                                shipping_address: default_address_attributes.stringify_keys)
    @order = Order.create!(checkout: checkout, buyer: @buyer, store: stores(:confirmed_store),
                           subtotal_cents: 79_900, shipping_cents: 0, commission_cents: 0,
                           total_cents: 79_900, currency: "EUR")
    @order.items.create!(listing: @listing, quantity: 1, unit_price_cents: 79_900,
                         shipping_cents: 0, title: @listing.title,
                         seller_name: stores(:confirmed_store).name, specs: {})
    @order.update!(tracking_carrier: "seur", tracking_number: "SEUR123")
    ActionMailer::Base.deliveries.clear
  end

  test "buyer confirmation renders HTML and text in the buyer locale" do
    email = OrderMailer.buyer_confirmation(@order)

    assert_equal [ @buyer.email ], email.to
    assert_equal I18n.t("order_mailer.buyer_confirmation.subject", number: @order.number, locale: :fr),
                 email.subject
    assert_includes email.text_part.body.to_s,
                    I18n.t("order_mailer.buyer_confirmation.greeting",
                           name: "Test Buyer", locale: :fr)
    assert_includes email.html_part.body.to_s, "/fr/orders/"
    assert_includes email.text_part.body.to_s, @order.number
  end

  test "seller new sale renders in the seller locale" do
    email = OrderMailer.seller_new_sale(@order)

    assert_equal [ @seller.email ], email.to
    assert_equal I18n.t("order_mailer.seller_new_sale.subject", number: @order.number, locale: :de),
                 email.subject
    assert_includes email.text_part.body.to_s, "/de/sell/sales/"
  end

  test "shipping and delivery emails use the right recipients" do
    shipped = OrderMailer.order_shipped(@order)
    delivered = OrderMailer.delivery_confirmed(@order)

    assert_equal [ @buyer.email ], shipped.to
    assert_includes shipped.text_part.body.to_s, "SEUR123"
    assert_equal [ @seller.email ], delivered.to
    assert_includes delivered.text_part.body.to_s, @order.number
  end

  test "cancellation email goes to the chosen recipient" do
    email = OrderMailer.order_cancelled(@order, recipient: @seller)

    assert_equal [ @seller.email ], email.to
    assert_equal I18n.t("order_mailer.order_cancelled.subject", number: @order.number, locale: :de),
                 email.subject
  end
end
