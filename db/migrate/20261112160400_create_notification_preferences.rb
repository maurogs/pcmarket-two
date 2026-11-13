# frozen_string_literal: true

class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, foreign_key: true, null: false
      t.string :kind, null: false
      t.boolean :in_app, null: false, default: true
      t.boolean :email, null: false, default: true

      t.timestamps
    end

    add_index :notification_preferences, %i[user_id kind], unique: true
  end
end
