# frozen_string_literal: true

class CreateRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :regions do |t|
      t.string  :country_code, null: false
      t.string  :name, null: false
      t.string  :code, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :regions, %i[country_code code], unique: true
    add_index :regions, :country_code
    add_foreign_key :regions, :countries, column: :country_code, primary_key: :code
  end
end
