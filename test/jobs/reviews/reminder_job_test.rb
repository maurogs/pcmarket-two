# frozen_string_literal: true

require "test_helper"

class ReviewReminderJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @buyer = users(:moderator)
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
      delivered_at: 4.days.ago,
      paid_at: 6.days.ago,
      subtotal_cents: 10_000,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 10_000,
      currency: "EUR"
    )
  end

  test "emails a reminder three days after delivery when there is no review" do
    assert_enqueued_email_with ReviewMailer, :reminder, args: [ @order ] do
      Reviews::ReminderJob.perform_now(@order.id)
    end
  end

  test "does not email when the buyer already reviewed the order" do
    Review.create!(order: @order, reviewer: @buyer, store: @store, rating: 5,
                   body: "A smooth and well-packed delivery.")

    assert_no_enqueued_emails do
      Reviews::ReminderJob.perform_now(@order.id)
    end
  end
end
