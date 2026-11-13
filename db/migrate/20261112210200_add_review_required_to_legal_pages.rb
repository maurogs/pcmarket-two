# frozen_string_literal: true

class AddReviewRequiredToLegalPages < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_pages, :review_required, :boolean, null: false, default: false
  end
end
