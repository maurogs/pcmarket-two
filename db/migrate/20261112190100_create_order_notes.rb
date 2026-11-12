# frozen_string_literal: true

class CreateOrderNotes < ActiveRecord::Migration[8.1]
  def up
    create_table :order_notes do |t|
      t.references :order, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end

    add_index :order_notes, [ :order_id, :created_at ]
  end

  def down
    drop_table :order_notes
  end
end
