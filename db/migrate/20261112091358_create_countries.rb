# frozen_string_literal: true

class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table :countries do |t|
      t.string  :code, null: false
      t.boolean :active, null: false, default: false
      t.string  :default_locale, null: false, default: "en"
      t.string  :currency, null: false, default: "EUR"
      t.decimal :vat_rate, precision: 5, scale: 2, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :countries, :code, unique: true
    add_index :countries, :position
  end
end
