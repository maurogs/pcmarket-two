# frozen_string_literal: true

require "test_helper"

class CartCheckoutTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @buyer = users(:moderator)
    @listing = listings(:published_gpu)
    @store = stores(:confirmed_store)
  end

  teardown do
    Flipper.disable(:guest_checkout)
  end

  test "adding an item redirects to the cart and updates the badge" do
    sign_in @buyer

    post cart_items_path(locale: :en), params: { listing_id: @listing.id }

    assert_redirected_to cart_path(locale: :en)
    cart = Cart.find_by!(user: @buyer)
    assert_equal 1, cart.items.count

    follow_redirect!
    assert_response :success
    assert_includes response.body, I18n.t("cart.title", locale: :en)
    assert_includes response.body, @listing.title
    assert_includes response.body, ">1<"
  end

  test "buy now adds the item and goes straight to checkout with only that item" do
    sign_in @buyer
    other = listings(:amd_gpu)
    build_cart(user: @buyer, listings: [ other ])

    post cart_items_path(locale: :en), params: { listing_id: @listing.id, buy_now: "1" }

    assert_redirected_to new_checkout_path(locale: :en, buy_now: @listing.id)
    assert_equal 2, Cart.find_by!(user: @buyer).items.count

    follow_redirect!
    assert_response :success
    assert_includes response.body, @listing.title
    assert_not_includes response.body, other.title
  end

  test "buyers cannot add their own listings" do
    sign_in users(:confirmed)

    post cart_items_path(locale: :en), params: { listing_id: @listing.id }

    assert_redirected_to listing_path(@listing, locale: :en)
    assert_equal 0, Cart.find_by!(user: users(:confirmed)).items.count
  end

  test "guests cannot add items while guest checkout is disabled" do
    post cart_items_path(locale: :en), params: { listing_id: @listing.id }

    assert_redirected_to listing_path(@listing, locale: :en)
    assert_equal 0, CartItem.count
  end

  test "guests can add items and reach checkout when guest checkout is enabled" do
    Flipper.enable(:guest_checkout)

    post cart_items_path(locale: :en), params: { listing_id: @listing.id, buy_now: "1" }

    assert_redirected_to new_checkout_path(locale: :en, buy_now: @listing.id)
    assert Cart.where(user_id: nil).exists?
    assert_equal 1, CartItem.count
  end

  test "buy now checkout only purchases the selected item and leaves the rest of the basket" do
    sign_in @buyer
    other = listings(:amd_gpu)
    build_cart(user: @buyer, listings: [ other ])
    post cart_items_path(locale: :en), params: { listing_id: @listing.id, buy_now: "1" }

    post checkout_path(locale: :en), params: {
      email: @buyer.email,
      terms_accepted: "1",
      idempotency_key: SecureRandom.uuid,
      buy_now_listing_id: @listing.id,
      address: default_address_attributes,
      fulfilment: { @store.id.to_s => "shipping" }
    }

    assert_redirected_to checkout_path(locale: :en)
    checkout = Checkout.find_by!(buyer: @buyer)
    assert_equal [ @listing.id ], checkout.orders.flat_map { |order| order.items.map(&:listing_id) }
    assert_equal [ other.id ], Cart.find_by!(user: @buyer).items.map(&:listing_id)
  end

  test "the checkout page renders the three sections and the cart summary" do
    sign_in @buyer
    build_cart(user: @buyer, listings: [ @listing ])

    get new_checkout_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("checkout.address.title", locale: :en)
    assert_includes response.body, I18n.t("checkout.shipping.title", locale: :en)
    assert_includes response.body, I18n.t("checkout.payment.title", locale: :en)
    assert_includes response.body, @listing.title
  end

  test "paying creates orders, marks them paid and shows the confirmation" do
    sign_in @buyer
    build_cart(user: @buyer, listings: [ @listing ])

    post checkout_path(locale: :en), params: {
      email: @buyer.email,
      terms_accepted: "1",
      idempotency_key: SecureRandom.uuid,
      address: default_address_attributes,
      fulfilment: { @store.id.to_s => "shipping" }
    }

    assert_redirected_to checkout_path(locale: :en)
    checkout = Checkout.find_by!(buyer: @buyer)
    assert checkout.paid?
    assert_equal 1, checkout.orders.count
    order = checkout.orders.first
    assert order.paid?
    assert_equal "sold", @listing.reload.status
    assert_enqueued_emails 2

    follow_redirect!
    assert_response :success
    assert_includes response.body, order.number
    assert_includes response.body, I18n.t("checkout.confirmation.title", locale: :en)
  end

  test "a declined payment returns to the checkout form with an error" do
    sign_in @buyer
    build_cart(user: @buyer, listings: [ @listing ])

    post checkout_path(locale: :en), params: {
      email: @buyer.email,
      terms_accepted: "1",
      idempotency_key: SecureRandom.uuid,
      payment_result: "failure",
      address: default_address_attributes,
      fulfilment: { @store.id.to_s => "shipping" }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("checkout.errors.payment_failed", locale: :en)
    assert_equal "published", @listing.reload.status
  end
end
