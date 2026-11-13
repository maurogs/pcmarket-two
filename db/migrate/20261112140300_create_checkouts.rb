# frozen_string_literal: true

class CreateCheckouts < ActiveRecord::Migration[8.1]
  def change
    create_table :checkouts do |t|
      t.references :buyer, foreign_key: { to_table: :users }, null: true
      t.string :status, null: false, default: "pending"
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :shipping_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :payment_intent_id
      t.datetime :expires_at
      t.jsonb :shipping_address, null: false, default: {}
      t.string :email
      t.string :idempotency_key

      t.timestamps
    end

    add_index :checkouts, :status
    add_index :checkouts, :expires_at
    add_index :checkouts, :idempotency_key, unique: true
  end
end
