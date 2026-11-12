# frozen_string_literal: true

class CreateOrderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :order_events do |t|
      t.references :order, foreign_key: true, null: false
      t.references :actor, foreign_key: { to_table: :users }, null: true
      t.string :event, null: false
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end

    add_index :order_events, %i[order_id created_at]
  end
end
