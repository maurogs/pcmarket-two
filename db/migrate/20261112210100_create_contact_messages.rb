# frozen_string_literal: true

class CreateContactMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.citext :email, null: false
      t.string :topic, null: false
      t.string :order_number
      t.text :message, null: false

      t.timestamps
    end

    add_index :contact_messages, [ :email, :created_at ]
  end
end
