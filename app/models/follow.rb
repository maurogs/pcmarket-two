# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", inverse_of: :follows
  belongs_to :store, counter_cache: :followers_count

  validates :store_id, uniqueness: { scope: :follower_id }

  scope :recent, -> { order(created_at: :desc) }
end
