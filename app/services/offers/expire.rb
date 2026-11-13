# frozen_string_literal: true

module Offers
  # Expires one pending offer and records it in the conversation.
  class Expire
    def initialize(offer:)
      @offer = offer
    end

    def call
      return false unless @offer.pending?

      expired = false

      Offer.transaction do
        @offer.with_lock do
          next unless @offer.pending?

          @offer.expire!
          Message.event!(
            conversation: @offer.conversation,
            sender: @offer.offerer,
            key: "offers.system.expired",
            metadata: metadata
          )
          expired = true
        end
      end

      notify if expired
      expired
    end

    private

    def metadata
      {
        amount_cents: @offer.amount_cents,
        currency: @offer.listing.currency,
        title: @offer.listing.title,
        offer_id: @offer.id,
        conversation_id: @offer.conversation_id
      }
    end

    def notify
      recipients = [ @offer.offerer, @offer.recipient ].compact.uniq
      recipients.each do |recipient|
        Notifications.record(
          recipient: recipient,
          kind: "offer_expired",
          notifiable: @offer,
          params: metadata
        )
      end
      OfferMailer.offer_expired(@offer).deliver_later
    end
  end
end
