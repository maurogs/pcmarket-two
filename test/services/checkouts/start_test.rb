# frozen_string_literal: true

require "test_helper"

class Checkouts::StartTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @confirmed_store = stores(:confirmed_store)
    @second_store = stores(:suspended_store)
    @second_store.update!(status: :active)
    @gpu = listings(:published_gpu)
    @other_listing = listings(:suspended_listing)
    @other_listing.update!(shipping_price_cents: 500, free_shipping: false,
                           shipping_mode: "shipping")
  end

  teardown do
    Flipper.disable(:commissions)
    Setting.set(:commission_enabled, false)
    Setting.set(:commission_percent, 0)
  end

  def start(cart:, buyer: @buyer, gateway: Payments::FakeGateway.new, **overrides)
    Checkouts::Start.new(
      cart: cart,
      buyer: buyer,
      params: checkout_params(fulfilment: fulfilment_hash, **overrides),
      gateway: gateway
    ).call
  end

  def fulfilment_hash
    {
      @confirmed_store.id.to_s => "shipping",
      @second_store.id.to_s => "shipping"
    }
  end

  test "creates one order per seller with snapshotted lines and per-seller shipping" do
    cart = build_cart(user: @buyer, listings: [ @gpu, @other_listing ])

    result = start(cart: cart)

    assert result.success?
    checkout = result.checkout
    assert_equal "pending", checkout.status
    assert_equal 2, checkout.orders.count
    assert_equal 95_400, checkout.total_cents

    first = checkout.orders.find_by!(store: @confirmed_store)
    assert_equal 79_900, first.subtotal_cents
    assert_equal 0, first.shipping_cents
    assert_equal 79_900, first.total_cents
    assert_equal 0, first.commission_cents
    assert_equal "EUR", first.currency
    line = first.items.first
    assert_equal @gpu.title, line.title
    assert_equal 79_900, line.unit_price_cents
    assert_equal @confirmed_store.name, line.seller_name

    second = checkout.orders.find_by!(store: @second_store)
    assert_equal 15_000, second.subtotal_cents
    assert_equal 500, second.shipping_cents
    assert_equal 15_500, second.total_cents

    assert_equal 95_400, checkout.orders.sum(&:total_cents)
  end

  test "reserves stock atomically and hides fully reserved listings" do
    cart = build_cart(user: @buyer, listings: [ @gpu, @other_listing ])

    assert start(cart: cart).success?

    assert_equal "reserved", @gpu.reload.status
    assert_equal 0, @gpu.quantity
    assert_equal "reserved", @other_listing.reload.status
    assert_equal 0, @other_listing.quantity
  end

  test "locks every cart listing in one query ordered by id before reserving" do
    cart = build_cart(user: @buyer, listings: [ @other_listing, @gpu ])
    statements = []

    subscriber = lambda do |*, payload|
      next if payload[:cached] || payload[:name] == "SCHEMA"

      statements << payload[:sql]
    end

    result = ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      start(cart: cart)
    end

    assert result.success?

    lock_statements = statements.select do |sql|
      sql.match?(/SELECT .* FROM "listings" .*ORDER BY "listings"\."id" ASC .*FOR UPDATE/m)
    end

    assert_equal 1, lock_statements.size,
                 "expected exactly one ordered listing lock query, got: #{lock_statements.inspect}"
  end

  test "stores commission only when the flag and setting are enabled" do
    Flipper.enable(:commissions)
    Setting.set(:commission_enabled, true)
    Setting.set(:commission_percent, 5.0)

    cart = build_cart(user: @buyer, listings: [ @gpu ])
    result = Checkouts::Start.new(cart: cart, buyer: @buyer,
                                  params: checkout_params(fulfilment: { @confirmed_store.id.to_s => "shipping" }),
                                  gateway: Payments::FakeGateway.new).call

    assert result.success?
    order = result.checkout.orders.first
    assert_equal 3995, order.subtotal_cents * 5 / 100
    assert_equal 3995, order.commission_cents
    assert_equal 79_900, order.total_cents
  end

  test "local pickup removes the shipping charge" do
    pickup = create_listing!(store: @confirmed_store, seller: users(:confirmed),
                             title: "Pickup only GPU", shipping_mode: "local_pickup",
                             shipping_price_cents: 900)
    cart = build_cart(user: @buyer, listings: [ pickup ])

    result = Checkouts::Start.new(
      cart: cart,
      buyer: @buyer,
      params: checkout_params(fulfilment: { @confirmed_store.id.to_s => "local_pickup" }),
      gateway: Payments::FakeGateway.new
    ).call

    assert result.success?
    order = result.checkout.orders.first
    assert order.fulfilment_local_pickup?
    assert_equal 0, order.shipping_cents
    assert_equal 0, order.total_cents - order.subtotal_cents
  end

  test "a second buyer cannot reserve an item already taken by the first checkout" do
    first_cart = build_cart(user: @buyer, listings: [ @gpu ])
    second_buyer = users(:admin)
    second_cart = build_cart(user: second_buyer, listings: [ @gpu ])

    assert start(cart: first_cart).success?

    result = start(cart: second_cart, buyer: second_buyer)

    assert_not result.success?
    assert_equal [ I18n.t("checkout.errors.unavailable_items") ], result.errors
    assert_nil result.checkout
    assert_equal 1, Checkout.where.not(id: nil).count
  end

  test "is idempotent for the same key" do
    cart = build_cart(user: @buyer, listings: [ @gpu ])

    first = start(cart: cart, idempotency_key: "key-123")
    second = start(cart: cart, idempotency_key: "key-123")

    assert first.success?
    assert second.success?
    assert_equal first.checkout, second.checkout
    assert_equal 1, first.checkout.orders.count
  end

  test "declined payments fail the checkout, cancel orders and release stock" do
    cart = build_cart(user: @buyer, listings: [ @gpu ])

    result = start(cart: cart, gateway: Payments::FakeGateway.new(failure: true))

    assert_not result.success?
    assert_equal "failed", result.checkout.status
    assert_equal "cancelled", result.checkout.orders.first.status
    assert_equal "published", @gpu.reload.status
    assert_equal 1, @gpu.quantity
  end

  test "rejects a checkout without accepted terms" do
    cart = build_cart(user: @buyer, listings: [ @gpu ])

    result = start(cart: cart, terms_accepted: "0")

    assert_not result.success?
    assert_equal [ I18n.t("checkout.errors.terms_required") ], result.errors
    assert_equal "published", @gpu.reload.status
  end
end
