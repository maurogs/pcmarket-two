# frozen_string_literal: true

class StripeWebhookJob < ApplicationJob
  queue_as :default

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find_by(id: webhook_event_id)
    return if webhook_event.nil?

    Webhooks::ProcessStripeEvent.new(webhook_event).call
  end
end
