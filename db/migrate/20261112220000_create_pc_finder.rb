# frozen_string_literal: true

class CreatePcFinder < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.jsonb :min_gpu_tier, null: false, default: {}
      t.jsonb :min_cpu_tier, null: false, default: {}

      t.timestamps
    end

    add_index :games, :slug, unique: true
    add_index :games, %i[active position]

    create_table :gpu_tiers do |t|
      t.string :pattern, null: false
      t.integer :tier, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :gpu_tiers, :pattern, unique: true
    add_index :gpu_tiers, %i[active tier]

    create_table :cpu_tiers do |t|
      t.string :pattern, null: false
      t.integer :tier, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :cpu_tiers, :pattern, unique: true
    add_index :cpu_tiers, %i[active tier]
  end
end
