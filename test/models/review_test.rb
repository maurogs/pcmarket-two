# frozen_string_literal: true

require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @buyer = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
  end

  def delivered_order(delivered_at: Time.current, buyer: @buyer)
    checkout = Checkout.create!(
      buyer: buyer,
      email: buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
    Order.create!(
      checkout: checkout,
      buyer: buyer,
      store: @store,
      status: "delivered",
      delivered_at: delivered_at,
      paid_at: delivered_at,
      subtotal_cents: 10_000,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 10_000,
      currency: "EUR"
    )
  end

  def build_review(order:, rating: 5, body: "A perfectly good buying experience.")
    Review.new(order: order, reviewer: order.buyer, store: order.store, rating: rating, body: body)
  end

  test "only the buyer of a delivered order can review it" do
    order = delivered_order
    review = build_review(order: order)

    assert review.valid?
    assert review.save

    duplicate = build_review(order: order)
    assert_not duplicate.valid?
    assert duplicate.errors[:order_id].any?
  end

  test "an order cannot be reviewed before delivery or after 60 days" do
    pending = delivered_order
    pending.update_columns(status: "shipped", delivered_at: nil)
    assert_not build_review(order: pending).valid?

    old_order = delivered_order(delivered_at: 61.days.ago)
    review = build_review(order: old_order)
    assert_not review.valid?
    assert review.errors[:order].any?
  end

  test "a review is editable for seven days" do
    review = build_review(order: delivered_order)
    assert review.save
    assert review.editable?

    review.update_column(:created_at, 8.days.ago)
    assert_not review.reload.editable?
  end

  test "the seller can reply only once" do
    review = build_review(order: delivered_order)
    assert review.save

    assert review.replyable_by?(@seller)
    assert_not review.replyable_by?(@buyer)

    review.update!(seller_reply: "Thank you for the feedback.", seller_replied_at: Time.current)

    assert review.seller_replied?
    assert_not review.replyable_by?(@seller)
  end

  test "store rating is recalculated from visible reviews" do
    five = build_review(order: delivered_order, rating: 5)
    three = build_review(order: delivered_order, rating: 3)
    assert five.save
    assert three.save

    @store.reload
    assert_equal 2, @store.ratings_count
    assert_equal 4.0, @store.rating_average.to_f

    five.update!(status: :hidden)

    @store.reload
    assert_equal 1, @store.ratings_count
    assert_equal 3.0, @store.rating_average.to_f
  end

  test "reviewer name is anonymised for deleted users" do
    review = build_review(order: delivered_order)
    assert review.save
    @buyer.update_columns(deleted_at: Time.current, first_name: nil, last_name: nil)

    assert_equal I18n.t("users.deleted"), review.reload.reviewer_name
  end
end
