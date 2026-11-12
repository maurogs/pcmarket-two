# frozen_string_literal: true

class Region < ApplicationRecord
  belongs_to :country, foreign_key: :country_code, primary_key: :code,
                       inverse_of: :regions

  validates :name, presence: true
  validates :code, presence: true,
                   uniqueness: { scope: :country_code }

  scope :ordered, -> { order(:position) }
end
