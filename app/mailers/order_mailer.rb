# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  layout "order_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def buyer_confirmation(order)
    @order = order
    @locale = order.buyer&.locale.presence || I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: order.checkout.recipient_email, subject: t("order_mailer.buyer_confirmation.subject", number: order.number))
    end
  end

  def seller_new_sale(order)
    @order = order
    @locale = order.store.user.locale.presence || I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: order.store.user.email, subject: t("order_mailer.seller_new_sale.subject", number: order.number))
    end
  end

  def order_shipped(order)
    @order = order
    @locale = order.buyer&.locale.presence || I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: order.checkout.recipient_email, subject: t("order_mailer.order_shipped.subject", number: order.number))
    end
  end

  def delivery_confirmed(order)
    @order = order
    @locale = order.store.user.locale.presence || I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: order.store.user.email, subject: t("order_mailer.delivery_confirmed.subject", number: order.number))
    end
  end

  def order_cancelled(order, recipient:)
    @order = order
    @recipient = recipient
    @locale = recipient_locale(recipient, order)

    I18n.with_locale(@locale) do
      mail(to: recipient_email(recipient, order), subject: t("order_mailer.order_cancelled.subject", number: order.number))
    end
  end

  private

  def recipient_locale(recipient, order)
    return recipient.locale.presence || I18n.default_locale if recipient.respond_to?(:locale)

    order.buyer&.locale.presence || I18n.default_locale
  end

  def recipient_email(recipient, order)
    return recipient.email if recipient.respond_to?(:email)

    order.checkout.recipient_email
  end
end
