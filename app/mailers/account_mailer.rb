# frozen_string_literal: true

class AccountMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def data_export(user, token)
    @user = user
    @locale = user.locale.presence || I18n.default_locale
    @download_url = account_data_export_url(token: token, locale: @locale)

    I18n.with_locale(@locale) do
      mail(to: user.email, subject: t("account_mailer.data_export.subject"))
    end
  end
end
