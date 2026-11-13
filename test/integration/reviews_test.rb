# frozen_string_literal: true

require "test_helper"

class ReviewsTest < ActionDispatch::IntegrationTest
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

  test "the buyer order page shows the review CTA and publishes a review" do
    sign_in @buyer
    get order_path(@order, locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("reviews.section.cta", locale: :en)

    assert_difference "Review.count", 1 do
      post order_review_path(@order, locale: :en), params: {
        review: { rating: 5, body: "Great seller and very fast delivery." }
      }
    end

    assert_redirected_to order_path(@order, locale: :en, anchor: "review")
    assert_equal 5.0, @store.reload.rating_average.to_f
  end

  test "a buyer can edit their review inside the seven-day window" do
    review = Review.create!(order: @order, reviewer: @buyer, store: @store,
                            rating: 4, body: "Good item and quick dispatch.")
    sign_in @buyer

    patch order_review_path(@order, locale: :en), params: {
      review: { rating: 5, body: "Updated: even better than expected." }
    }

    assert_redirected_to order_path(@order, locale: :en, anchor: "review")
    assert_equal 5, review.reload.rating
  end

  test "the seller can reply once from the sale page" do
    review = Review.create!(order: @order, reviewer: @buyer, store: @store,
                            rating: 5, body: "Excellent packaging and communication.")
    sign_in @seller

    get sell_order_path(@order, locale: :en)
    assert_response :success

    post review_seller_reply_path(review, locale: :en), params: {
      review: { seller_reply: "Thank you for buying with us." }
    }

    assert_redirected_to sell_order_path(@order, locale: :en)
    assert review.reload.seller_replied?
  end

  test "another buyer cannot review someone else's order" do
    sign_in users(:admin)

    post order_review_path(@order, locale: :en), params: {
      review: { rating: 1, body: "This should never be allowed." }
    }

    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized", locale: :es), flash[:alert]
  end
end
