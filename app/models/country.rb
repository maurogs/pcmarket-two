# frozen_string_literal: true

class Country < ApplicationRecord
  LAUNCHED_CODES_CACHE_KEY = "countries/launched_codes"

  has_many :regions, foreign_key: :country_code, primary_key: :code,
                     inverse_of: :country, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true,
                   format: { with: /\A[A-Z]{2}\z/ }
  validates :default_locale, presence: true
  validates :currency, presence: true

  scope :active, -> { where(active: true).order(:position) }
  scope :ordered, -> { order(:position) }

  after_commit :clear_launched_codes_cache

  def self.launched_codes
    Rails.cache.fetch(LAUNCHED_CODES_CACHE_KEY) do
      active.pluck(:code)
    end
  end

  def name
    I18n.t("countries.#{code.downcase}")
  end

  private

  def clear_launched_codes_cache
    Rails.cache.delete(LAUNCHED_CODES_CACHE_KEY)
  end
end
