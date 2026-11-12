# frozen_string_literal: true

class AddStripeConnectFieldsToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :stripe_account_id, :string
    add_column :stores, :payouts_enabled, :boolean, null: false, default: false
    add_column :stores, :charges_enabled, :boolean, null: false, default: false
    add_column :stores, :details_submitted, :boolean, null: false, default: false
    add_column :stores, :requirements, :jsonb, null: false, default: {}

    add_index :stores, :stripe_account_id, unique: true
  end
end
