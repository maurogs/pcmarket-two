module Localization
  extend ActiveSupport::Concern

  private

  # Wraps every action in the detected locale and remembers the choice.
  def switch_locale(&action)
    locale = detected_locale
    cookies[:locale] = { value: locale.to_s, expires: 1.year.from_now }
    I18n.with_locale(locale, &action)
  end

  # Priority: explicit param, stored cookie, Accept-Language header, default locale.
  def detected_locale
    locale_from_params || locale_from_cookie || locale_from_header || I18n.default_locale
  end

  def locale_from_params
    normalize_locale(params[:locale])
  end

  def locale_from_cookie
    normalize_locale(cookies[:locale])
  end

  def locale_from_header
    request.headers["Accept-Language"].to_s.split(",").each do |entry|
      language = entry.split(";").first.to_s.strip.split("-").first
      locale = normalize_locale(language)
      return locale if locale
    end

    nil
  end

  def normalize_locale(value)
    locale = value.to_s.strip.downcase.to_sym
    I18n.available_locales.include?(locale) ? locale : nil
  end
end
