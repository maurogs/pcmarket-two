# frozen_string_literal: true

class AllowNullDraftPrice < ActiveRecord::Migration[8.1]
  def up
    change_column_null :listings, :price_cents, true
  end

  def down
    change_column_null :listings, :price_cents, false
  end
end
