# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def new_message(message)
    @message = message
    @conversation = message.conversation
    @recipient = @conversation.other_party_for(message.sender)
    @locale = @recipient.locale.presence || I18n.default_locale
    @cta_url = conversation_url(@conversation, locale: @locale)

    I18n.with_locale(@locale) do
      mail(to: @recipient.email,
           subject: t("message_mailer.new_message.subject", sender: message.sender.display_name))
    end
  end
end
