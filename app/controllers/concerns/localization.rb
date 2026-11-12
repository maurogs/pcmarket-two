module Localization
  extend ActiveSupport::Concern

  # Parses an Accept-Language header without touching params or cookies so the
  # JSON API can reuse the exact same negotiation rules.
  def self.locale_from_header(header)
    header.to_s.split(",").each do |entry|
      language = entry.split(";").first.to_s.strip.split("-").first
      locale = normalize(language)
      return locale if locale
    end

    nil
  end

  def self.normalize(value)
    locale = value.to_s.strip.downcase.to_sym
    I18n.available_locales.include?(locale) ? locale : nil
  end

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
    Localization.locale_from_header(request.headers["Accept-Language"])
  end

  def normalize_locale(value)
    Localization.normalize(value)
  end
end
