# frozen_string_literal: true

class CountryPreferencesController < ApplicationController
  def update
    code = params[:country].to_s.upcase

    if Country.launched_codes.include?(code)
      cookies[:country] = {
        value: code,
        expires: 1.year.from_now,
        httponly: true,
        same_site: :lax
      }
      redirect_back fallback_location: root_path
    else
      redirect_back fallback_location: root_path, alert: t("country_preference.invalid")
    end
  end
end
