# frozen_string_literal: true

class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :api_session, null: true, foreign_key: true
      t.string :platform, null: false, default: "other"
      t.string :token, null: false
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
    add_index :device_tokens, [ :user_id, :platform ]
  end
end
