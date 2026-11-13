# frozen_string_literal: true

# Launch countries. ES is live; the rest stay inactive until their
# localisation, shipping and legal work is complete.
COUNTRIES = [
  { code: "ES", active: true,  default_locale: "es", currency: "EUR", vat_rate: 21, position: 1 },
  { code: "FR", active: false, default_locale: "fr", currency: "EUR", vat_rate: 20, position: 2 },
  { code: "GB", active: false, default_locale: "en", currency: "GBP", vat_rate: 20, position: 3 },
  { code: "DE", active: false, default_locale: "de", currency: "EUR", vat_rate: 19, position: 4 },
  { code: "IT", active: false, default_locale: "it", currency: "EUR", vat_rate: 22, position: 5 },
  { code: "PT", active: false, default_locale: "pt", currency: "EUR", vat_rate: 23, position: 6 }
].freeze

COUNTRIES.each do |attributes|
  Country.find_or_create_by!(code: attributes[:code]) do |country|
    country.assign_attributes(attributes)
  end
end
