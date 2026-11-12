# frozen_string_literal: true

class BuybackMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def status_update(request, event)
    @request = request
    @event = event.to_s
    @locale = request.user&.locale.presence || I18n.default_locale
    @status_url = buyback_request_url(request, locale: @locale)

    I18n.with_locale(@locale) do
      subject = t("buyback_mailer.events.#{@event}.subject", reference: request.reference)
      mail(to: request.user.email, subject: subject)
    end
  end
end
