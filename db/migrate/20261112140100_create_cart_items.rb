# frozen_string_literal: true

class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, foreign_key: true, null: false
      t.references :listing, foreign_key: true, null: false
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end

    add_index :cart_items, %i[cart_id listing_id], unique: true
  end
end
