# frozen_string_literal: true

class Country < ApplicationRecord
  LAUNCHED_CODES_CACHE_KEY = "countries/launched_codes"
  LAUNCHED_COUNTRIES_CACHE_KEY = "countries/launched_countries"

  has_many :regions, foreign_key: :country_code, primary_key: :code,
                     inverse_of: :country, dependent: :restrict_with_exception
  has_many :legal_pages, foreign_key: :country_code, primary_key: :code,
                         inverse_of: :country, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true,
                   format: { with: /\A[A-Z]{2}\z/ }
  validates :default_locale, presence: true
  validates :currency, presence: true

  scope :active, -> { where(active: true).order(:position) }
  scope :ordered, -> { order(:position) }

  after_commit :clear_launched_codes_cache
  after_commit :bump_listing_search_cache, if: :saved_change_to_active?

  validate :activation_requirements_met, if: :activating?

  def self.launched_codes
    Rails.cache.fetch(LAUNCHED_CODES_CACHE_KEY) do
      active.pluck(:code)
    end
  end

  # The full rows for launched countries, ordered for the footer selector.
  # Cached with the same invalidation as launched_codes.
  def self.launched_countries
    Rails.cache.fetch(LAUNCHED_COUNTRIES_CACHE_KEY) do
      where(code: launched_codes).order(:position).to_a
    end
  end

  def name
    I18n.t("countries.#{code.downcase}")
  end

  # Ordered checklist shown on the admin country screen. `ok` is true when the
  # requirement is satisfied.
  def launch_checks
    locales = [ default_locale.to_s ]
    published_kinds = LegalPage.published
                              .where(country_code: code, locale: locales)
                              .distinct.map(&:kind)
    missing = LegalPage::KINDS - published_kinds

    [
      {
        key: "legal_pages",
        ok: missing.empty?,
        missing: missing
      },
      {
        key: "regions",
        ok: regions.exists?,
        count: regions.count
      }
    ]
  end

  def launch_ready?
    launch_checks.all? { |check| check[:ok] }
  end

  private

  def activating?
    persisted? && will_save_change_to_active? && active?
  end

  def activation_requirements_met
    reasons = launch_checks.reject { |check| check[:ok] }
    return if reasons.empty?

    errors.add(:active, I18n.t("countries.errors.not_ready",
                               reasons: activation_reasons(reasons).to_sentence))
  end

  def activation_reasons(checks)
    checks.map do |check|
      if check[:key] == "legal_pages"
        I18n.t("countries.errors.missing_legal_pages",
               kinds: check[:missing].map { |kind| I18n.t("legal_pages.kinds.#{kind}") }
                         .to_sentence)
      else
        I18n.t("countries.errors.missing_regions")
      end
    end
  end

  def clear_launched_codes_cache
    Rails.cache.delete(LAUNCHED_CODES_CACHE_KEY)
    Rails.cache.delete(LAUNCHED_COUNTRIES_CACHE_KEY)
  end

  def bump_listing_search_cache
    Rails.cache.write(Listing::SEARCH_CACHE_VERSION_KEY, Time.current.to_f)
  end
end
