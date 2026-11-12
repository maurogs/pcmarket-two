# frozen_string_literal: true

# Handles the human unsubscribe link (GET) and the RFC 8058 one-click POST.
# The signed token is the credential, so no session is required.
class EmailUnsubscribesController < ApplicationController
  skip_forgery_protection only: :create

  def show
    unsubscribe
  end

  def create
    unsubscribe
  end

  private

  def unsubscribe
    data = EmailUnsubscribe.verify(params[:token])

    if data.present? && EmailUnsubscribe.apply(data)
      redirect_to root_path, notice: t("email_unsubscribe.flash.success")
    else
      redirect_to root_path, alert: t("email_unsubscribe.flash.invalid")
    end
  end

  # One-click requests come from mail providers and email clients, not browsers.
  def allow_browser(**)
    nil
  end
end
