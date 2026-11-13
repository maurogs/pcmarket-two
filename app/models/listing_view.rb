# frozen_string_literal: true

# One row per listing and day. Views are incremented with an atomic upsert so
# the analytics daily series never needs to scan the listings table.
class ListingView < ApplicationRecord
  belongs_to :listing

  validates :date, presence: true
  validates :views, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :listing_id, uniqueness: { scope: :date }

  def self.increment_for(listing_id, date: Date.current)
    now = Time.current
    sql = sanitize_sql_array([ <<~SQL.squish, listing_id, date, now, now ])
      INSERT INTO listing_views (listing_id, date, views, created_at, updated_at)
      VALUES (?, ?, 1, ?, ?)
      ON CONFLICT (listing_id, date)
      DO UPDATE SET views = listing_views.views + 1, updated_at = EXCLUDED.updated_at
    SQL
    connection.execute(sql)
  end
end
