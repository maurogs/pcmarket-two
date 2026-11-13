# frozen_string_literal: true

module Offers
  # Seller accepts, declines or counters a pending offer. Each decision posts a
  # system message and notifies the other party by email and in-app.
  class Respond
    Result = Struct.new(:success, :offer, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(offer:, actor:, decision:, amount_cents: nil, message: nil)
      @offer = offer
      @actor = actor
      @decision = decision.to_s
      @amount_cents = amount_cents
      @message = message
    end

    def call
      return failure("offers.errors.not_pending") unless @offer.pending?
      return failure("offers.errors.expired") if @offer.expired_by_time?
      unless @decision == "withdraw"
        return failure("offers.errors.not_recipient") unless @offer.recipient&.id == @actor.id
      end

      case @decision
      when "accept" then accept
      when "decline" then decline
      when "counter" then counter
      when "withdraw" then withdraw
      else failure("offers.errors.invalid_decision")
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, offer: e.record, errors: e.record.errors.full_messages)
    end

    private

    def accept
      Offer.transaction do
        @offer.with_lock do
          @offer.accept!
          post_event("offers.system.accepted")
        end
        notify(@offer.offerer, "offer_accepted", @offer)
      end
      Result.new(success: true, offer: @offer, errors: [])
    end

    def decline
      Offer.transaction do
        @offer.with_lock do
          @offer.decline!
          post_event("offers.system.declined")
        end
        notify(@offer.offerer, "offer_declined", @offer)
      end
      Result.new(success: true, offer: @offer, errors: [])
    end

    def counter
      counter = nil
      Offer.transaction do
        @offer.with_lock do
          @offer.mark_countered!
          counter = Offer.create!(
            listing: @offer.listing,
            buyer: @offer.buyer,
            conversation: @offer.conversation,
            offerer: @actor,
            counter_offer: @offer,
            amount_cents: @amount_cents,
            message: @message
          )
          post_event("offers.system.countered", amount_cents: counter.amount_cents)
        end
        notify(@offer.offerer, "offer_countered", counter)
      end
      Result.new(success: true, offer: counter, errors: [])
    end

    # The party who made the offer can retract it while it is still pending.
    def withdraw
      return failure("offers.errors.not_offerer") unless @offer.offerer_id == @actor.id

      Offer.transaction do
        @offer.with_lock do
          @offer.withdraw!
          post_event("offers.system.withdrawn")
        end
      end

      Result.new(success: true, offer: @offer, errors: [])
    end

    def post_event(key, amount_cents: @offer.amount_cents)
      Message.event!(
        conversation: @offer.conversation,
        sender: @actor,
        key: key,
        metadata: {
          amount_cents: amount_cents,
          currency: @offer.listing.currency,
          title: @offer.listing.title,
          offer_id: @offer.id,
          conversation_id: @offer.conversation_id
        }
      )
    end

    def notify(recipient, kind, offer)
      return if recipient.blank?

      Notifications.record(
        recipient: recipient,
        kind: kind,
        notifiable: offer,
        params: {
          amount_cents: offer.amount_cents,
          currency: offer.listing.currency,
          title: offer.listing.title,
          offer_id: offer.id,
          conversation_id: offer.conversation_id
        }
      )
      mail = OfferMailer.public_send(kind, offer)
      mail.deliver_later
    end

    def failure(key)
      Result.new(success: false, offer: @offer, errors: [ I18n.t(key) ])
    end
  end
end
