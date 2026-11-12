# frozen_string_literal: true

class CreateLegalPages < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_pages do |t|
      t.string :country_code, null: false
      t.string :locale, null: false
      t.integer :kind, null: false, default: 0
      t.string :title, null: false
      t.string :version, null: false
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.datetime :effective_at
      t.datetime :notified_at

      t.timestamps
    end

    add_index :legal_pages, %i[country_code locale kind version], unique: true,
              name: "index_legal_pages_on_country_locale_kind_version"
    add_index :legal_pages, %i[country_code locale kind status],
              name: "index_legal_pages_on_country_locale_kind_status"
    add_foreign_key :legal_pages, :countries, column: :country_code, primary_key: :code
  end
end
