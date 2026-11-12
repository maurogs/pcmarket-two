# frozen_string_literal: true

class CreateAttributeCatalogue < ActiveRecord::Migration[8.1]
  def change
    create_table :attribute_definitions do |t|
      t.string  :key, null: false
      t.jsonb   :name, null: false, default: {}
      t.string  :group
      t.integer :input_type, null: false, default: 0
      t.string  :unit
      t.boolean :filterable, null: false, default: true
      t.boolean :show_on_card, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :attribute_definitions, :key, unique: true
    add_index :attribute_definitions, %i[group position]
    add_index :attribute_definitions, :active

    create_table :attribute_options do |t|
      t.references :attribute_definition, null: false, foreign_key: true
      t.string  :value, null: false
      t.jsonb   :label, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :popular, null: false, default: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :attribute_options, %i[attribute_definition_id value], unique: true
    add_index :attribute_options, %i[attribute_definition_id position]

    create_table :category_attributes do |t|
      t.references :category, null: false, foreign_key: true
      t.references :attribute_definition, null: false, foreign_key: true
      t.boolean :required, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :category_attributes, %i[category_id attribute_definition_id], unique: true
  end
end
