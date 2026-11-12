# frozen_string_literal: true

class ListingMailer < ApplicationMailer
  layout "listing_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def approved(listing)
    prepare(listing)

    I18n.with_locale(@locale) do
      mail(to: @listing.seller.email, subject: t("listing_mailer.approved.subject"))
    end
  end

  def rejected(listing)
    prepare(listing)

    I18n.with_locale(@locale) do
      mail(to: @listing.seller.email, subject: t("listing_mailer.rejected.subject"))
    end
  end

  private

  def prepare(listing)
    @listing = listing
    @locale = listing.seller.locale.presence || I18n.default_locale
  end
end
