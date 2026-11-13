# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :checkout, foreign_key: true, null: false
      t.references :buyer, foreign_key: { to_table: :users }, null: true
      t.references :store, foreign_key: true, null: false
      t.string :number
      t.string :status, null: false, default: "pending_payment"
      t.integer :fulfilment, null: false, default: 0
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :shipping_cents, null: false, default: 0
      t.integer :commission_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "EUR"
      t.string :tracking_carrier
      t.string :tracking_number
      t.datetime :paid_at
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.datetime :buyer_protection_ends_at

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :status
    add_index :orders, %i[store_id status]
    add_index :orders, %i[buyer_id created_at]
    add_index :orders, %i[checkout_id store_id], unique: true
  end
end
