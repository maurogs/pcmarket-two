# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.integer :kind, null: false, default: 0
      t.jsonb   :name, null: false, default: {}
      t.string  :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.string  :colour

      t.timestamps
    end

    add_index :tags, %i[kind slug], unique: true
    add_index :tags, %i[kind position]
    add_index :tags, :kind
  end
end
