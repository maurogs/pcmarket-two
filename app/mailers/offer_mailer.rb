# frozen_string_literal: true

class OfferMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def new_offer(offer)
    prepare(offer, offer.listing.seller, "new_offer")
  end

  def offer_accepted(offer)
    prepare(offer, offer.offerer, "offer_accepted")
  end

  def offer_declined(offer)
    prepare(offer, offer.offerer, "offer_declined")
  end

  def offer_countered(offer)
    prepare(offer, offer.counter_offer&.offerer || offer.offerer, "offer_countered")
  end

  def offer_expiring(offer)
    prepare(offer, offer.recipient, "offer_expiring")
  end

  def offer_expired(offer)
    prepare(offer, offer.offerer, "offer_expired")
  end

  private

  def prepare(offer, recipient, event)
    @offer = offer
    @listing = offer.listing
    @recipient = recipient
    @event = event
    @locale = recipient.locale.presence || I18n.default_locale
    @cta_url = conversation_url(offer.conversation, locale: @locale)

    I18n.with_locale(@locale) do
      mail(to: recipient.email,
           subject: t("offer_mailer.#{event}.subject", title: @listing.title),
           template_name: "notification")
    end
  end
end
