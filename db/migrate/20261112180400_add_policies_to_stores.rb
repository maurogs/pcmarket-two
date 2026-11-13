# frozen_string_literal: true

class AddPoliciesToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :return_policy, :text
    add_column :stores, :shipping_policy, :text
    add_column :stores, :handling_days, :integer, null: false, default: 3
  end
end
