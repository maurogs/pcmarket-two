# frozen_string_literal: true

# Devise reconfirmable is enabled in config/initializers/devise.rb. The
# unconfirmed_email column already exists, so this migration adds the lookup
# index used when a user confirms a changed address.
class AddUnconfirmedEmailIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :unconfirmed_email
  end
end
