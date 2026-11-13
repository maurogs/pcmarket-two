# frozen_string_literal: true

class CreateNewsletterSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_subscriptions do |t|
      t.citext :email, null: false
      t.string :locale, null: false, default: "es"
      t.string :token, null: false
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at

      t.timestamps
    end

    add_index :newsletter_subscriptions, :email, unique: true
    add_index :newsletter_subscriptions, :token, unique: true
  end
end
