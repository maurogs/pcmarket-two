# frozen_string_literal: true

require "test_helper"

class NewsletterSubscriptionTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "normalises the email and can be confirmed and unsubscribed" do
    subscription = NewsletterSubscription.create!(email: "  Person@Example.COM ", locale: "en")

    assert_equal "person@example.com", subscription.email
    assert subscription.token.present?
    assert_not subscription.active?

    assert subscription.confirm!
    assert subscription.reload.active?

    subscription.unsubscribe!
    assert subscription.reload.unsubscribed_at.present?
    assert_not subscription.active?
  end

  test "re-requesting a confirmed subscription does not enqueue another email" do
    subscription = NewsletterSubscription.create!(email: "member@example.com", locale: "es")
    subscription.confirm!

    assert_no_enqueued_emails do
      NewsletterSubscription.request(email: "member@example.com", locale: "es")
    end
  end

  test "rate limits repeated requests from the same IP" do
    with_cache(ActiveSupport::Cache::MemoryStore.new) do
      5.times do |index|
        record = NewsletterSubscription.request(
          email: "person#{index}@example.com", locale: "es", ip: "203.0.113.9"
        )
        assert_empty record.errors
      end

      blocked = NewsletterSubscription.request(
        email: "person6@example.com", locale: "es", ip: "203.0.113.9"
      )
      assert blocked.errors.any?
      assert_not blocked.persisted?
    end
  end
end
