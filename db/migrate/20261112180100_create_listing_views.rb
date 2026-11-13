# frozen_string_literal: true

class CreateListingViews < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_views do |t|
      t.references :listing, foreign_key: true, null: false, index: false
      t.date :date, null: false
      t.integer :views, null: false, default: 0

      t.timestamps
    end

    add_index :listing_views, %i[listing_id date], unique: true
    add_index :listing_views, :date
  end
end
