# frozen_string_literal: true

class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, foreign_key: true, null: false
      t.references :listing, foreign_key: true, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false, default: 0
      t.integer :shipping_cents, null: false, default: 0
      t.string :title, null: false
      t.string :seller_name, null: false
      t.string :photo_url
      t.jsonb :specs, null: false, default: {}

      t.timestamps
    end

    add_index :order_items, %i[order_id listing_id], unique: true
  end
end
