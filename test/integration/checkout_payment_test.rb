# frozen_string_literal: true

require "test_helper"

class CheckoutPaymentTest < ActionDispatch::IntegrationTest
  class PaymentElementGateway < Payments::Gateway
    def create_payment(checkout:)
      Result.new(success: true, payment_intent_id: "pi_element_123",
                 client_secret: "pi_element_123_secret", error: nil)
    end
  end

  setup do
    @buyer = users(:moderator)
    @listing = listings(:published_gpu)
    @store = stores(:confirmed_store)
  end

  test "a pending checkout renders the Stripe Payment Element" do
    checkout = pending_checkout
    sign_in @buyer

    with_stub(Payments, :stripe_publishable_key, "pk_test_element") do
      get checkout_path(locale: :en)
    end

    assert_response :success
    assert_includes response.body, "https://js.stripe.com/v3/"
    assert_includes response.body, "pk_test_element"
    assert_includes response.body, checkout.payment_client_secret
    assert_includes response.body, 'data-controller="stripe-payment"'
    assert_includes response.body, 'data-stripe-payment-locale-value="en"'
    assert_includes response.body, "http://www.example.com/en/checkout"
    assert_includes response.body, I18n.t("checkout.payment_page.pay", locale: :en)
  end

  test "stripe.js is not loaded on ordinary pages" do
    sign_in @buyer

    get root_path(locale: :en)

    assert_response :success
    assert_not_includes response.body, "js.stripe.com"
  end

  test "a pending checkout without a client secret shows the confirming message" do
    pending_checkout(client_secret: nil)
    sign_in @buyer

    get checkout_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("checkout.payment_page.confirming_title", locale: :en)
    assert_includes response.body, '<meta http-equiv="refresh" content="5">'
    assert_not_includes response.body, "js.stripe.com"
  end

  test "the checkout form shows Stripe copy when real payments are configured" do
    @store.update!(payouts_enabled: true)
    sign_in @buyer
    build_cart(user: @buyer, listings: [ @listing ])

    with_stub(Payments, :fake_gateway?, false) do
      get new_checkout_path(locale: :en)
    end

    assert_response :success
    assert_includes response.body, I18n.t("checkout.payment.stripe_title", locale: :en)
    assert_includes response.body, I18n.t("checkout.payment.continue", locale: :en)
    assert_not_includes response.body, I18n.t("checkout.payment.fake_title", locale: :en)
  end

  test "a checkout with a client secret redirects to the payment page instead of completing" do
    sign_in @buyer
    build_cart(user: @buyer, listings: [ @listing ])

    with_stub(Payments, :gateway, PaymentElementGateway.new) do
      post checkout_path(locale: :en), params: checkout_form
    end

    assert_redirected_to checkout_path(locale: :en)
    checkout = Checkout.find_by!(buyer: @buyer)
    assert checkout.pending?
    assert_equal "pi_element_123_secret", checkout.payment_client_secret
    assert_equal "pending_payment", checkout.orders.first.status
    assert_equal I18n.t("checkout.flash.redirect_to_payment", locale: :en), flash[:notice]

    follow_redirect!
    assert_response :success
    assert_includes response.body, "pi_element_123_secret"
  end

  test "reusing a pending checkout with a client secret keeps redirecting to payment" do
    sign_in @buyer
    build_cart(user: @buyer, listings: [ @listing ])
    gateway = PaymentElementGateway.new

    with_stub(Payments, :gateway, gateway) do
      post checkout_path(locale: :en), params: checkout_form
      assert_difference "Checkout.count", 0 do
        post checkout_path(locale: :en), params: checkout_form
      end
    end

    assert_redirected_to checkout_path(locale: :en)
    assert Checkout.find_by!(buyer: @buyer).pending?
  end

  private

  def checkout_form
    {
      email: @buyer.email,
      terms_accepted: "1",
      idempotency_key: "idem-element-123",
      address: default_address_attributes,
      fulfilment: { @store.id.to_s => "shipping" }
    }
  end

  def pending_checkout(client_secret: "pi_element_123_secret")
    checkout = Checkout.create!(
      buyer: @buyer,
      email: @buyer.email,
      shipping_address: default_address_attributes.stringify_keys,
      status: "pending",
      payment_intent_id: "pi_element_123",
      payment_client_secret: client_secret
    )
    Order.create!(
      checkout: checkout,
      buyer: @buyer,
      store: @store,
      status: "pending_payment",
      subtotal_cents: 79_900,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 79_900,
      currency: "EUR"
    )
    checkout
  end
end
