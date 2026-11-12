# frozen_string_literal: true

class AddVacationUntilToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :vacation_until, :date
  end
end
