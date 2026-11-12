# frozen_string_literal: true

class CookieConsentsController < ApplicationController
  def create
    categories = params.fetch(:cookie_consent, {})
                       .permit(*CookieConsent::CATEGORIES)
                       .to_h

    payload = CookieConsent.payload(categories)
    cookies[CookieConsent::COOKIE_NAME] = {
      value: payload.to_json,
      expires: CookieConsent::MAX_AGE.from_now,
      httponly: false,
      same_site: :lax
    }

    CookieConsent.record!(user: current_user, categories: payload["categories"], request: request) if user_signed_in?

    redirect_back fallback_location: root_path, notice: t("cookie_consent.flash.saved")
  end
end
