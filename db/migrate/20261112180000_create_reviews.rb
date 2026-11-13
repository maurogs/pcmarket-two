# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :order, foreign_key: true, null: false, index: { unique: true }
      t.references :reviewer, foreign_key: { to_table: :users }, null: false
      t.references :store, foreign_key: true, null: false
      t.integer :rating, null: false
      t.text :body, null: false
      t.text :seller_reply
      t.datetime :seller_replied_at
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :reviews, %i[store_id status created_at]
    add_index :reviews, %i[reviewer_id created_at]
  end
end
