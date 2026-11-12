# frozen_string_literal: true

class LegalPageMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def notice(user, legal_page_id)
    @user = user
    @legal_page = LegalPage.find(legal_page_id)
    @locale = user.locale.presence || @legal_page.country.default_locale.presence ||
              I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: user.email,
           subject: t("legal_page_mailer.notice.subject",
                      title: @legal_page.title))
    end
  end
end
