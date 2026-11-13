# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def user_banned(user, reason)
    @user = user
    @reason = reason
    @locale = user.locale.presence || I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: user.email, subject: t("admin_mailer.user_banned.subject"))
    end
  end

  def store_suspended(store, reason)
    @store = store
    @reason = reason
    @locale = store.user.locale.presence || I18n.default_locale

    I18n.with_locale(@locale) do
      mail(to: store.user.email, subject: t("admin_mailer.store_suspended.subject"))
    end
  end
end
