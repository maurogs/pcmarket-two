# frozen_string_literal: true

module OffersHelper
  include MoneyHelper

  def offer_status_label(offer)
    t("offers.statuses.#{offer.status}")
  end

  def offer_amount(offer)
    money(offer.amount_cents, currency: offer.listing.currency)
  end

  def offer_actionable?(offer, user)
    offer.acceptable_by?(user)
  end

  def offer_redeemable?(offer, user)
    offer.redeemable_by?(user)
  end

  def offer_counterparty(offer, user)
    offer.offerer_id == user.id ? offer.recipient : offer.offerer
  end
end
