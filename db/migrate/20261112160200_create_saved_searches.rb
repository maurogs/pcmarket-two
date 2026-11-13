# frozen_string_literal: true

class CreateSavedSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_searches do |t|
      t.references :user, foreign_key: true, null: false
      t.string :name, null: false
      t.jsonb :query_params, null: false, default: {}
      t.references :category, foreign_key: true, null: true
      t.boolean :email_alerts, null: false, default: true
      t.string :frequency, null: false, default: "daily"
      t.datetime :last_notified_at
      t.bigint :last_matched_listing_id

      t.timestamps
    end

    add_index :saved_searches, %i[user_id frequency]
    add_index :saved_searches, :last_matched_listing_id
  end
end
