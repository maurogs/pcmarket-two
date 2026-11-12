# frozen_string_literal: true

class AddPaymentClientSecretToCheckouts < ActiveRecord::Migration[8.1]
  def change
    add_column :checkouts, :payment_client_secret, :string
  end
end
