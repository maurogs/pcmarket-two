# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def notification(contact_message)
    @contact_message = contact_message
    @locale = I18n.default_locale

    I18n.with_locale(@locale) do
      mail(
        to: Setting.get(:support_email, "support@pcmarket.example"),
        reply_to: contact_message.email,
        subject: t("contact_mailer.notification.subject",
                   topic: t("contact.topics.#{contact_message.topic}"))
      )
    end
  end
end
