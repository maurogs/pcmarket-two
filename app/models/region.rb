# frozen_string_literal: true

class Region < ApplicationRecord
  belongs_to :country, foreign_key: :country_code, primary_key: :code,
                       inverse_of: :regions

  has_many :listings, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true,
                   uniqueness: { scope: :country_code }

  scope :ordered, -> { order(:position) }
  scope :for_country, ->(code) { where(country_code: code) }

  after_commit :expire_cached_options

  # Region names/VAT prefixes rarely change; every filter and address form can
  # share one cached ordered list per country.
  def self.cached_for_country(code)
    Rails.cache.fetch([ "regions/options", code ]) { for_country(code).ordered.to_a }
  end

  private

  def expire_cached_options
    Rails.cache.delete([ "regions/options", country_code ])
  end
end
