# frozen_string_literal: true

class CreateApiSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :api_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :refresh_token_digest, null: false
      t.string :device_name
      t.string :platform, null: false, default: "other"
      t.string :app_version
      t.datetime :last_used_at
      t.datetime :expires_at, null: false
      t.datetime :refresh_expires_at, null: false
      t.datetime :revoked_at
      t.string :ip

      t.timestamps
    end

    add_index :api_sessions, :token_digest, unique: true
    add_index :api_sessions, :refresh_token_digest, unique: true
    add_index :api_sessions, [ :user_id, :revoked_at ]
  end
end
