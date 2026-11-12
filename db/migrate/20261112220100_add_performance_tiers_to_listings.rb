# frozen_string_literal: true

class AddPerformanceTiersToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :gpu_tier, :integer, null: false, default: 0
    add_column :listings, :cpu_tier, :integer, null: false, default: 0

    add_index :listings, %i[gpu_tier cpu_tier]
    add_index :listings, :price_cents, name: "index_listings_on_price_cents_and_tiers"
  end
end
