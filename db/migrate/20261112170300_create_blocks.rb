# frozen_string_literal: true

class CreateBlocks < ActiveRecord::Migration[8.1]
  def up
    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }
      t.references :blocked, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :blocks, %i[blocker_id blocked_id], unique: true
  end

  def down
    drop_table :blocks
  end
end
