# frozen_string_literal: true

class AlertMailer < ApplicationMailer
  layout "alert_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def price_drop(user, listing)
    prepare(user)
    @listing = listing
    @cta_url = listing_url(listing, locale: @locale)
    @unsubscribe_url = unsubscribe_url(user, kind: "price_drop")
    apply_unsubscribe_headers

    I18n.with_locale(@locale) do
      mail(to: user.email, subject: t("alert_mailer.price_drop.subject", title: listing.title))
    end
  end

  def followed_store_new_listing(user, store, listings)
    prepare(user)
    @store = store
    @listings = listings
    @cta_url = listing_url(listings.first, locale: @locale) if listings.any?
    @unsubscribe_url = unsubscribe_url(user, kind: "followed_store_new_listing")
    apply_unsubscribe_headers

    I18n.with_locale(@locale) do
      mail(to: user.email, subject: t("alert_mailer.followed_store_new_listing.subject", store: store.name))
    end
  end

  def saved_search_match(saved_search, listing)
    prepare(saved_search.user)
    @saved_search = saved_search
    @listing = listing
    @cta_url = listing_url(listing, locale: @locale)
    @unsubscribe_url = unsubscribe_url(
      saved_search.user, saved_search: saved_search, kind: "saved_search_match"
    )
    apply_unsubscribe_headers

    I18n.with_locale(@locale) do
      mail(to: saved_search.user.email,
           subject: t("alert_mailer.saved_search_match.subject", name: saved_search.name))
    end
  end

  def saved_search_digest(user, entries)
    prepare(user)
    @entries = entries
    first_search = entries.first&.dig(:saved_search)
    @cta_url = search_url(first_search.to_search_params.merge(locale: @locale)) if first_search
    @unsubscribe_url = unsubscribe_url(user, kind: "saved_search_match")
    apply_unsubscribe_headers

    I18n.with_locale(@locale) do
      mail(to: user.email, subject: t("alert_mailer.saved_search_digest.subject"))
    end
  end

  private

  def prepare(user)
    @user = user
    @locale = user.locale.presence || I18n.default_locale
  end

  def unsubscribe_url(user, saved_search: nil, kind: nil)
    token = EmailUnsubscribe.token(user: user, saved_search: saved_search, kind: kind)
    email_unsubscribe_url(token: token, locale: @locale)
  end

  def apply_unsubscribe_headers
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end
end
