# frozen_string_literal: true

class NewsletterSubscriptionsController < ApplicationController
  def create
    @subscription = NewsletterSubscription.request(
      email: params[:email],
      locale: I18n.locale,
      ip: request.remote_ip
    )

    if @subscription.errors.any?
      redirect_back fallback_location: root_path,
                    alert: @subscription.errors.full_messages.to_sentence
    else
      redirect_back fallback_location: root_path, notice: t("newsletter.flash.check_email")
    end
  end
end
