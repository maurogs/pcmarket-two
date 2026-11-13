# frozen_string_literal: true

class CreateOffers < ActiveRecord::Migration[8.1]
  def up
    create_table :offers do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :conversation, null: false, foreign_key: true
      t.references :offerer, null: false, foreign_key: { to_table: :users }
      t.references :counter_offer, foreign_key: { to_table: :offers }
      t.integer :amount_cents, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at
      t.datetime :expiry_reminder_sent_at
      t.text :message
      t.timestamps
    end

    add_index :offers, %i[listing_id buyer_id],
              unique: true,
              where: "status = 'pending' AND counter_offer_id IS NULL",
              name: "index_offers_on_listing_and_buyer_pending"
    add_index :offers, %i[status expires_at]
  end

  def down
    drop_table :offers
  end
end
