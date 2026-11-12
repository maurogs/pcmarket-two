# frozen_string_literal: true

class CreatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :payouts do |t|
      t.references :order, foreign_key: true, null: false, index: { unique: true }
      t.references :store, foreign_key: true, null: false
      t.integer :amount_cents, null: false, default: 0
      t.string :stripe_transfer_id
      t.string :status, null: false, default: "pending"
      t.text :error

      t.timestamps
    end

    add_index :payouts, :stripe_transfer_id
  end
end
