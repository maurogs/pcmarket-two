# frozen_string_literal: true

require "test_helper"

class ReviewPolicyTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    checkout = Checkout.create!(
      buyer: @buyer,
      email: @buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
    @order = Order.create!(
      checkout: checkout,
      buyer: @buyer,
      store: @store,
      status: "delivered",
      delivered_at: Time.current,
      paid_at: Time.current,
      subtotal_cents: 10_000,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 10_000,
      currency: "EUR"
    )
  end

  test "the buyer can create a review for a delivered order" do
    review = Review.new(order: @order, reviewer: @buyer, store: @store)

    assert ReviewPolicy.new(@buyer, review).create?
    assert_not ReviewPolicy.new(@seller, review).create?
  end

  test "the buyer can edit inside the window and the seller can reply once" do
    review = Review.create!(order: @order, reviewer: @buyer, store: @store,
                            rating: 5, body: "Excellent item and quick delivery.")

    assert ReviewPolicy.new(@buyer, review).update?
    assert_not ReviewPolicy.new(@seller, review).update?
    assert ReviewPolicy.new(@seller, review).reply?
    assert_not ReviewPolicy.new(@buyer, review).reply?

    review.update!(seller_reply: "Thanks!", seller_replied_at: Time.current)
    assert_not ReviewPolicy.new(@seller, review).reply?
  end

  test "editing closes after seven days" do
    review = Review.create!(order: @order, reviewer: @buyer, store: @store,
                            rating: 4, body: "Good item with a small scratch.")
    review.update_column(:created_at, 8.days.ago)

    assert_not ReviewPolicy.new(@buyer, review.reload).update?
  end
end
