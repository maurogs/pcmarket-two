# frozen_string_literal: true

class AddRegionToStores < ActiveRecord::Migration[8.1]
  def change
    add_reference :stores, :region, foreign_key: true, index: true
  end
end
