# frozen_string_literal: true

module Offers
  # Recurring sweep: expires overdue offers and reminds the party who has to
  # respond when an offer is about to expire.
  class ExpiryJob < ApplicationJob
    queue_as :default

    REMINDER_WINDOW = 6.hours

    def perform
      Offer.due.find_each { |offer| Offers::Expire.new(offer: offer).call }
      send_reminders
    end

    private

    def send_reminders
      Offer.pending
          .where(expiry_reminder_sent_at: nil)
          .where(expires_at: ..REMINDER_WINDOW.from_now)
          .find_each do |offer|
        next unless offer.expiring_soon?

        remind(offer)
      end
    end

    def remind(offer)
      recipient = offer.recipient
      return if recipient.blank?

      Notifications.record(
        recipient: recipient,
        kind: "offer_expiring",
        notifiable: offer,
        params: {
          amount_cents: offer.amount_cents,
          currency: offer.listing.currency,
          title: offer.listing.title,
          offer_id: offer.id,
          conversation_id: offer.conversation_id
        }
      )
      OfferMailer.offer_expiring(offer).deliver_later
      offer.update_column(:expiry_reminder_sent_at, Time.current)
    end
  end
end
