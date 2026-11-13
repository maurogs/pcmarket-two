# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, foreign_key: true, null: true
      t.string :full_name, null: false
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.references :region, foreign_key: true, null: true
      t.string :postal_code, null: false
      t.string :country_code, null: false, default: "ES"
      t.string :phone, null: false
      t.boolean :default, null: false, default: false

      t.timestamps
    end

    add_index :addresses, %i[user_id default]
  end
end
