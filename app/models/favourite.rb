# frozen_string_literal: true

class Favourite < ApplicationRecord
  belongs_to :user
  belongs_to :listing, counter_cache: :favorites_count

  validates :listing_id, uniqueness: { scope: :user_id }

  scope :recent, -> { order(created_at: :desc) }
end
