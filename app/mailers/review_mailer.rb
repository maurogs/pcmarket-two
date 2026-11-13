# frozen_string_literal: true

class ReviewMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def reminder(order)
    @order = order
    @store = order.store
    @locale = order.buyer&.locale.presence || I18n.default_locale
    @review_url = order_url(order, locale: @locale, anchor: "review")

    I18n.with_locale(@locale) do
      mail(to: order.checkout.recipient_email,
           subject: t("review_mailer.reminder.subject", store: @store.name))
    end
  end
end
