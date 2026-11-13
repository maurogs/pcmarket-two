# frozen_string_literal: true

module Buyback
  # Applies one staff transition, stores the inspection/tracking data and
  # enqueues the translated email. Returning false keeps the request state and
  # lets the admin screen explain what is missing.
  class Advance
    EVENTS = {
      "label_sent" => :send_label,
      "received" => :receive,
      "inspected" => :mark_inspected,
      "offer_revised" => :revise_offer,
      "accepted_revision" => :accept_revision,
      "paid" => :mark_paid,
      "rejected" => :reject,
      "returned" => :return_to_sender
    }.freeze

    def initialize(request:, event:, attributes: {})
      @request = request
      @event = event.to_s
      @attributes = attributes.to_h
    end

    def call
      return false unless EVENTS.key?(@event)

      applying_revision = @event == "inspected" && revised_offer_cents.positive?
      event = applying_revision ? :revise_offer : EVENTS.fetch(@event)
      email_event = applying_revision ? "offer_revised" : @event

      @request.assign_attributes(permitted_attributes)
      @request.revised_offer_cents = revised_offer_cents if applying_revision

      if applying_revision && !@request.inspected?
        return false unless @request.may_mark_inspected? && @request.mark_inspected!
      end

      return false unless @request.public_send("may_#{event}?")
      return false unless @request.public_send("#{event}!")

      BuybackMailer.status_update(@request, email_event).deliver_later
      true
    end

    private

    def permitted_attributes
      @attributes.slice("carrier", "tracking_number", "inspection_result")
    end

    def revised_offer_cents
      raw = @attributes["revised_offer"].to_s
      return 0 if raw.blank?

      (BigDecimal(raw) * 100).round
    rescue ArgumentError, TypeError
      0
    end
  end
end
