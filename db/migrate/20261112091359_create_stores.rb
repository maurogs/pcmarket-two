# frozen_string_literal: true

class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string  :name, null: false
      t.string  :slug, null: false
      t.text    :description
      t.integer :kind, null: false, default: 0
      t.string  :legal_name
      t.string  :tax_id
      t.string  :address_line
      t.string  :city
      t.string  :province
      t.string  :postal_code
      t.string  :country_code, null: false, default: "ES"
      t.string  :phone
      t.string  :website
      t.datetime :verified_at
      t.boolean :vacation_mode, null: false, default: false
      t.text    :vacation_message
      t.boolean :allow_offers_default, null: false, default: true
      t.integer :status, null: false, default: 0
      t.decimal :rating_average, precision: 3, scale: 2, null: false, default: 0
      t.integer :ratings_count, null: false, default: 0
      t.integer :listings_count, null: false, default: 0
      t.integer :sales_count, null: false, default: 0
      t.integer :followers_count, null: false, default: 0

      t.timestamps
    end

    add_index :stores, :slug, unique: true
    add_index :stores, :status
    add_index :stores, :country_code
  end
end
