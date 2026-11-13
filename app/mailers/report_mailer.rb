# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  layout "notification_mailer"

  default from: "PCMarket <no-reply@pcmarket.example>"

  def acknowledgement(report)
    @report = report
    @locale = reporter_locale(report)
    @cta_url = root_url(locale: @locale)

    I18n.with_locale(@locale) do
      mail(to: report.contact_email, subject: t("report_mailer.acknowledgement.subject"))
    end
  end

  def decision(report)
    @report = report
    @locale = reporter_locale(report)
    @cta_url = root_url(locale: @locale)

    I18n.with_locale(@locale) do
      mail(to: report.contact_email,
           subject: t("report_mailer.decision.subject", decision: t("report_mailer.decisions.#{report.status}")))
    end
  end

  private

  def reporter_locale(report)
    report.reporter&.locale.presence || I18n.default_locale
  end
end
