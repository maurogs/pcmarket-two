# frozen_string_literal: true

class CreateFavourites < ActiveRecord::Migration[8.1]
  def change
    create_table :favourites do |t|
      t.references :user, foreign_key: true, null: false
      t.references :listing, foreign_key: true, null: false

      t.timestamps
    end

    add_index :favourites, %i[user_id listing_id], unique: true
  end
end
