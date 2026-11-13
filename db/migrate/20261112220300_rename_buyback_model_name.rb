# frozen_string_literal: true

class RenameBuybackModelName < ActiveRecord::Migration[8.1]
  def change
    rename_column :buyback_prices, :model_name, :component_model
    rename_column :buyback_quotes, :model_name, :component_model
    rename_column :buyback_requests, :model_name, :component_model
  end
end
