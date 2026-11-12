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
end
