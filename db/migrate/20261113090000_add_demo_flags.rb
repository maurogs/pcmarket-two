# frozen_string_literal: true

# Marks rows created by `pcmarket:demo:seed` so `pcmarket:demo:reset` can remove
# only demo data and leave real development accounts untouched.
class AddDemoFlags < ActiveRecord::Migration[8.1]
  TABLES = %i[users stores listings].freeze

  def up
    TABLES.each do |table|
      add_column table, :demo, :boolean, default: false, null: false
      add_index table, :demo
    end
  end

  def down
    TABLES.reverse_each do |table|
      remove_index table, :demo
      remove_column table, :demo
    end
  end
end
