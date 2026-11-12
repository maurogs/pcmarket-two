# frozen_string_literal: true

class CartItemsController < ApplicationController
  def create
    listing = Listing.with_card_includes.friendly.find(params[:listing_id])
    cart = persistent_cart
    authorize cart, :update?

    result = Carts::AddItem.new(cart: cart,
                                listing: listing,
                                quantity: quantity_param).call

    if result.success?
      if buy_now?
        redirect_to new_checkout_path(buy_now: listing.id)
      else
        redirect_back fallback_location: cart_path, notice: t("cart.flash.added")
      end
    else
      redirect_back fallback_location: listing_path(listing), alert: result.errors.first
    end
  end

  def update
    item = current_cart.items.find(params[:id])
    authorize item, :update?
    quantity = quantity_param

    if quantity.positive? && item.update(quantity: quantity)
      redirect_to cart_path, notice: t("cart.flash.updated")
    elsif quantity <= 0 && item.destroy
      redirect_to cart_path, notice: t("cart.flash.removed")
    else
      redirect_to cart_path, alert: item.errors.full_messages.first
    end
  end

  def destroy
    item = current_cart.items.find(params[:id])
    authorize item, :destroy?
    item.destroy!
    redirect_to cart_path, notice: t("cart.flash.removed")
  end

  private

  def quantity_param
    params.fetch(:quantity, 1).to_i
  end

  def buy_now?
    ActiveModel::Type::Boolean.new.cast(params[:buy_now])
  end
end
