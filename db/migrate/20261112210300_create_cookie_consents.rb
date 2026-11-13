# frozen_string_literal: true

class CreateCookieConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :cookie_consents do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :categories, null: false, default: {}
      t.string :version, null: false
      t.datetime :consented_at, null: false
      t.string :ip
      t.string :user_agent

      t.timestamps
    end

    add_index :cookie_consents, [ :user_id, :created_at ]
  end
end
