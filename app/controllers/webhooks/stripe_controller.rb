# frozen_string_literal: true

module Webhooks
  # Receives Stripe events, verifies their signature and stores them before the
  # asynchronous handler runs. Stripe must receive a 2xx quickly.
  class StripeController < ActionController::Base
    skip_forgery_protection

    def create
      secret = Payments.stripe_webhook_secret
      return head :bad_request if secret.blank?

      event = Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers["HTTP_STRIPE_SIGNATURE"],
        secret
      )

      webhook_event = store_event(event)
      StripeWebhookJob.perform_later(webhook_event.id) if webhook_event.previously_new_record?

      head :ok
    rescue Stripe::SignatureVerificationError, JSON::ParserError
      head :bad_request
    end

    private

    def store_event(event)
      WebhookEvent.find_or_create_by!(provider: "stripe", event_id: event.id) do |webhook_event|
        webhook_event.type = event.type
        webhook_event.payload = event.to_hash
      end
    rescue ActiveRecord::RecordNotUnique
      WebhookEvent.find_by!(provider: "stripe", event_id: event.id)
    end
  end
end
