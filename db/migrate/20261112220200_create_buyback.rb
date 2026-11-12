# frozen_string_literal: true

class CreateBuyback < ActiveRecord::Migration[8.1]
  def change
    create_table :buyback_prices do |t|
      t.integer :component_type, null: false, default: 0
      t.string :model_name, null: false
      t.integer :base_offer_cents, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.jsonb :condition_multipliers, null: false, default: {
        "like_new" => 1.0,
        "good" => 0.85,
        "fair" => 0.7,
        "for_parts" => 0.25
      }

      t.timestamps
    end

    add_index :buyback_prices, %i[component_type model_name], unique: true
    add_index :buyback_prices, %i[active component_type]

    create_table :buyback_quotes do |t|
      t.references :buyback_price, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :component_type, null: false, default: 0
      t.string :model_name, null: false
      t.string :condition, null: false
      t.jsonb :answers, null: false, default: {}
      t.integer :offer_cents, null: false, default: 0
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :buyback_quotes, :token, unique: true
    add_index :buyback_quotes, :expires_at

    create_table :buyback_requests do |t|
      t.references :buyback_quote, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :component_type, null: false, default: 0
      t.string :model_name, null: false
      t.string :condition, null: false
      t.jsonb :condition_answers, null: false, default: {}
      t.string :status, null: false, default: "quoted"
      t.string :reference, null: false
      t.integer :offer_cents, null: false, default: 0
      t.integer :revised_offer_cents
      t.text :iban
      t.string :iban_last4
      t.string :full_name
      t.string :line1
      t.string :line2
      t.string :city
      t.string :postal_code
      t.string :country_code, null: false, default: "ES"
      t.string :phone
      t.string :carrier
      t.string :tracking_number
      t.text :inspection_result
      t.datetime :accepted_at
      t.datetime :label_sent_at
      t.datetime :received_at
      t.datetime :inspected_at
      t.datetime :revised_at
      t.datetime :paid_at
      t.datetime :rejected_at
      t.datetime :returned_at

      t.timestamps
    end

    add_index :buyback_requests, :reference, unique: true
    add_index :buyback_requests, %i[user_id created_at]
    add_index :buyback_requests, %i[status created_at]
  end
end
