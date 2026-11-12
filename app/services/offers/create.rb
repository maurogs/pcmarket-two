# frozen_string_literal: true

module Offers
  # Buyer-initiated offer: finds or creates the listing conversation, validates
  # the offer and posts the offer event in the chat.
  class Create
    Result = Struct.new(:success, :offer, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(listing:, buyer:, amount_cents:, message: nil)
      @listing = listing
      @buyer = buyer
      @amount_cents = amount_cents
      @message = message
    end

    def call
      return failure("offers.errors.disabled") unless Flipper.enabled?(:offers)
      return failure("offers.errors.unavailable") unless @listing.allow_offers? && @listing.publicly_visible?
      return failure("offers.errors.self") if @buyer.id == @listing.user_id
      return failure("offers.errors.blocked") if Block.between?(@buyer, @listing.seller)

      offer = nil

      Offer.transaction do
        conversation = find_or_create_conversation
        offer = Offer.new(
          listing: @listing,
          buyer: @buyer,
          conversation: conversation,
          offerer: @buyer,
          amount_cents: @amount_cents,
          message: @message
        )
        offer.save!

        Message.event!(
          conversation: conversation,
          sender: @buyer,
          kind: :offer,
          key: "offers.system.created",
          metadata: metadata(offer)
        )
        notify_seller(offer)
      end

      Result.new(success: true, offer: offer, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, offer: e.record, errors: e.record.errors.full_messages)
    end

    private

    def find_or_create_conversation
      existing = Conversation.between(@buyer, @listing.seller, listing: @listing)
      return existing if existing.present?

      Conversation.create!(
        listing: @listing,
        buyer: @buyer,
        seller: @listing.seller,
        store: @listing.store
      )
    end

    def notify_seller(offer)
      Notifications.record(
        recipient: @listing.seller,
        kind: "new_offer",
        notifiable: offer,
        params: metadata(offer).merge(buyer_name: @buyer.display_name)
      )
      OfferMailer.new_offer(offer).deliver_later
    end

    def metadata(offer)
      {
        amount_cents: offer.amount_cents,
        currency: @listing.currency,
        title: @listing.title,
        offer_id: offer.id,
        conversation_id: offer.conversation_id
      }
    end

    def failure(key)
      Result.new(success: false, offer: nil, errors: [ I18n.t(key) ])
    end
  end
end
