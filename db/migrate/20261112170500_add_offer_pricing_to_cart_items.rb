# frozen_string_literal: true

class AddOfferPricingToCartItems < ActiveRecord::Migration[8.1]
  def up
    add_reference :cart_items, :offer, foreign_key: true
    add_column :cart_items, :unit_price_cents, :integer
  end

  def down
    remove_column :cart_items, :unit_price_cents
    remove_reference :cart_items, :offer, foreign_key: true
  end
end
