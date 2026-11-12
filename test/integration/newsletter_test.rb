# frozen_string_literal: true

require "test_helper"

class NewsletterTest < ActionDispatch::IntegrationTest
  test "signs up with double opt-in, confirms and unsubscribes" do
    assert_difference "NewsletterSubscription.count", 1 do
      post newsletter_subscriptions_path, params: { email: "new-reader@example.com" }
    end

    subscription = NewsletterSubscription.find_by!(email: "new-reader@example.com")
    assert_nil subscription.confirmed_at
    assert_enqueued_emails 1

    get newsletter_confirmation_path(token: subscription.token)
    assert_response :success
    assert subscription.reload.confirmed_at.present?

    get newsletter_unsubscription_path(token: subscription.token)
    assert_response :success
    assert subscription.reload.unsubscribed_at.present?
  end

  test "returns a translated error for an invalid address" do
    assert_no_difference "NewsletterSubscription.count" do
      post newsletter_subscriptions_path, params: { email: "not-an-email" }
    end

    assert_redirected_to root_path
    assert flash[:alert].present?
  end

  test "rate limits repeated requests from the same IP" do
    with_cache(ActiveSupport::Cache::MemoryStore.new) do
      5.times do |index|
        post newsletter_subscriptions_path, params: { email: "reader#{index}@example.com" }
      end

      assert_no_difference "NewsletterSubscription.count" do
        post newsletter_subscriptions_path, params: { email: "reader-blocked@example.com" }
      end

      assert_redirected_to root_path
      assert flash[:alert].present?
    end
  end
end
