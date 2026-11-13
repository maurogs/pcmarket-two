# frozen_string_literal: true

class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :user, foreign_key: true, null: true, index: { unique: true }
      t.string :token

      t.timestamps
    end

    add_index :carts, :token, unique: true
  end
end
