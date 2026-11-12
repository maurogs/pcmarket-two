# frozen_string_literal: true

class AllowNullWizardListingFields < ActiveRecord::Migration[8.1]
  def up
    change_column_null :listings, :title, true
    change_column_null :listings, :description, true
  end

  def down
    change_column_null :listings, :title, false
    change_column_null :listings, :description, false
  end
end
