# frozen_string_literal: true

module Api
  module V1
    class OfferSerializer < BaseSerializer
      attributes :id, :listing_id, :conversation_id, :buyer_id, :offerer_id,
                 :amount_cents, :status, :message, :expires_at,
                 :counter_offer_id, :created_at, :updated_at

      attribute :currency do |offer|
        offer.listing.currency.presence || "EUR"
      end

      attribute :recipient_id do |offer|
        offer.recipient&.id
      end

      attribute :acceptable do |offer|
        params[:user].present? && offer.acceptable_by?(params[:user])
      end

      attribute :redeemable do |offer|
        params[:user].present? && offer.redeemable_by?(params[:user])
      end
    end
  end
end
