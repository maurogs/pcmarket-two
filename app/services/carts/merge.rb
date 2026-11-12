# frozen_string_literal: true

module Carts
  # Merges the signed-cookie guest cart into the user cart after sign-in.
  class Merge
    def initialize(guest_cart:, user_cart:)
      @guest_cart = guest_cart
      @user_cart = user_cart
    end

    def call
      return @user_cart if @guest_cart.blank? || @user_cart.blank?
      return @user_cart if @guest_cart.id == @user_cart.id

      @guest_cart.items.includes(:listing).find_each do |item|
        Carts::AddItem.new(cart: @user_cart, listing: item.listing, quantity: item.quantity).call
      end

      @guest_cart.destroy!
      @user_cart
    end
  end
end
