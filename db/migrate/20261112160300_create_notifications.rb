# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, foreign_key: { to_table: :users }, null: false
      t.string :kind, null: false
      t.references :notifiable, polymorphic: true, null: true
      t.jsonb :params, null: false, default: {}
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, %i[recipient_id read_at created_at]
    add_index :notifications, :kind
  end
end
