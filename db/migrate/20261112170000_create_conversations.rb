# frozen_string_literal: true

class CreateConversations < ActiveRecord::Migration[8.1]
  def up
    create_table :conversations do |t|
      t.references :listing, foreign_key: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.references :store, null: false, foreign_key: true
      t.datetime :last_message_at
      t.integer :buyer_unread_count, null: false, default: 0
      t.integer :seller_unread_count, null: false, default: 0
      t.boolean :buyer_archived, null: false, default: false
      t.boolean :seller_archived, null: false, default: false
      t.timestamps
    end

    add_index :conversations, %i[listing_id buyer_id], unique: true
    add_index :conversations, %i[store_id buyer_id],
              unique: true,
              where: "listing_id IS NULL",
              name: "index_conversations_on_store_and_buyer_without_listing"
    add_index :conversations, %i[buyer_id last_message_at]
    add_index :conversations, %i[seller_id last_message_at]
  end

  def down
    drop_table :conversations
  end
end
