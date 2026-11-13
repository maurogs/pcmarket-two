# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :parent, foreign_key: { to_table: :categories }, index: false
      t.jsonb   :name, null: false, default: {}
      t.jsonb   :description, null: false, default: {}
      t.jsonb   :seo_title, null: false, default: {}
      t.jsonb   :seo_description, null: false, default: {}
      t.string  :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.string  :icon
      t.integer :depth, null: false, default: 0
      t.integer :listings_count, null: false, default: 0

      t.timestamps
    end

    add_index :categories, %i[parent_id position]
    add_index :categories, :slug, unique: true
    add_index :categories, :active
  end
end
