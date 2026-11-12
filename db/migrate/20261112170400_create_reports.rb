# frozen_string_literal: true

class CreateReports < ActiveRecord::Migration[8.1]
  def up
    create_table :reports do |t|
      t.references :reporter, foreign_key: { to_table: :users }
      t.string :reporter_email
      t.references :reportable, polymorphic: true, null: false
      t.integer :reason, null: false
      t.text :details, null: false
      t.integer :status, null: false, default: 0
      t.text :resolution_note
      t.references :handled_by, foreign_key: { to_table: :users }
      t.datetime :handled_at
      t.timestamps
    end

    add_index :reports, %i[status created_at]
    add_index :reports, :reason
  end

  def down
    drop_table :reports
  end
end
