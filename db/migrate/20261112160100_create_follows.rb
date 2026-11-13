# frozen_string_literal: true

class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :follower, foreign_key: { to_table: :users }, null: false
      t.references :store, foreign_key: true, null: false
      t.datetime :last_notified_at

      t.timestamps
    end

    add_index :follows, %i[follower_id store_id], unique: true
    add_index :follows, %i[store_id last_notified_at]
  end
end
