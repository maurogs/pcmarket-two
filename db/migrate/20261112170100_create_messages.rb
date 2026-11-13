# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.1]
  def up
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.integer :kind, null: false, default: 0
      t.datetime :read_at
      t.datetime :hidden_at
      t.boolean :safety_flagged, null: false, default: false
      t.jsonb :safety_reasons, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :messages, %i[conversation_id created_at]
    add_index :messages, %i[sender_id created_at]
  end

  def down
    drop_table :messages
  end
end
