# frozen_string_literal: true

module Conversations
  # Finds the buyer/seller conversation for a listing or store, enforcing the
  # self-message and block rules. Returns a result object for the controller.
  class FindOrCreate
    Result = Struct.new(:success, :conversation, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(buyer:, listing: nil, store: nil)
      @buyer = buyer
      @listing = listing
      @store = store || listing&.store
    end

    def call
      return failure("conversations.errors.self") if seller.blank? || seller.id == @buyer.id
      return failure("conversations.errors.blocked") if Block.between?(@buyer, seller)
      return failure("conversations.errors.unavailable") unless available?

      existing = Conversation.between(@buyer, seller, listing: @listing, store: @store)
      return reopen(existing) if existing.present?

      conversation = Conversation.new(
        listing: @listing,
        buyer: @buyer,
        seller: seller,
        store: @store
      )

      if conversation.save
        Result.new(success: true, conversation: conversation, errors: [])
      else
        Result.new(success: false, conversation: conversation,
                    errors: conversation.errors.full_messages)
      end
    end

    private

    def seller
      @listing&.seller || @store&.user
    end

    def available?
      return @listing.publicly_visible? if @listing.present?

      @store&.active?
    end

    def reopen(conversation)
      column = conversation.buyer_side?(@buyer) ? :buyer_archived : :seller_archived
      conversation.update_columns(column => false) if conversation.public_send(column)
      Result.new(success: true, conversation: conversation, errors: [])
    end

    def failure(key)
      Result.new(success: false, conversation: nil, errors: [ I18n.t(key) ])
    end
  end
end
