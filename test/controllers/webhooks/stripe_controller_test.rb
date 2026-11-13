# frozen_string_literal: true

require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  SECRET = "whsec_test_secret"

  setup do
    @payload = {
      id: "evt_test_123",
      type: "account.updated",
      data: { object: { id: "acct_test_123", payouts_enabled: true } }
    }.to_json
  end

  test "stores a signed event and enqueues the processing job" do
    with_stub(Payments, :stripe_webhook_secret, SECRET) do
      assert_difference "WebhookEvent.count", 1 do
        post_signed_event
      end
    end

    assert_response :ok
    webhook_event = WebhookEvent.last
    assert_equal "stripe", webhook_event.provider
    assert_equal "evt_test_123", webhook_event.event_id
    assert_equal "account.updated", webhook_event.type
    assert_equal "account.updated", webhook_event.payload["type"]
    assert_enqueued_with(job: StripeWebhookJob, args: [ webhook_event.id ])
  end

  test "rejects an invalid signature without storing the event" do
    with_stub(Payments, :stripe_webhook_secret, SECRET) do
      assert_no_difference "WebhookEvent.count" do
        post stripe_webhook_path, params: @payload,
             headers: { "Stripe-Signature" => "t=#{Time.now.to_i},v1=deadbeef",
                        "Content-Type" => "application/json" }
      end
    end

    assert_response :bad_request
    assert_no_enqueued_jobs
  end

  test "rejects events when the webhook secret is missing" do
    with_stub(Payments, :stripe_webhook_secret, nil) do
      assert_no_difference "WebhookEvent.count" do
        post stripe_webhook_path, params: @payload,
             headers: { "Content-Type" => "application/json" }
      end
    end

    assert_response :bad_request
  end

  test "duplicate events are acknowledged without enqueuing twice" do
    with_stub(Payments, :stripe_webhook_secret, SECRET) do
      post_signed_event
      clear_enqueued_jobs

      assert_no_difference "WebhookEvent.count" do
        post_signed_event
      end
    end

    assert_response :ok
    assert_no_enqueued_jobs
  end

  test "a concurrent duplicate insert is recovered without enqueuing a job" do
    WebhookEvent.create!(provider: "stripe", event_id: "evt_test_123",
                         type: "account.updated", payload: {})
    duplicate_raiser = lambda do |*_args, **_kwargs, &_block|
      raise ActiveRecord::RecordNotUnique, "duplicate key value"
    end

    with_stub(Payments, :stripe_webhook_secret, SECRET) do
      with_stub(WebhookEvent, :find_or_create_by!, duplicate_raiser) do
        assert_no_difference "WebhookEvent.count" do
          post_signed_event
        end
      end
    end

    assert_response :ok
    assert_no_enqueued_jobs
  end

  private

  def post_signed_event
    timestamp = Time.now
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, @payload, SECRET)
    header = Stripe::Webhook::Signature.generate_header(timestamp, signature)

    post stripe_webhook_path, params: @payload,
         headers: { "Stripe-Signature" => header, "Content-Type" => "application/json" }
  end
end
