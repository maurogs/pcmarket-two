# frozen_string_literal: true

class NewsletterMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def confirmation(subscription)
    @subscription = subscription
    @locale = subscription.locale.presence || I18n.default_locale
    @confirm_url = newsletter_confirmation_url(token: subscription.token, locale: @locale)
    @unsubscribe_url = newsletter_unsubscription_url(token: subscription.token, locale: @locale)

    I18n.with_locale(@locale) do
      mail(to: subscription.email,
           subject: t("newsletter_mailer.confirmation.subject"))
    end
  end
end
