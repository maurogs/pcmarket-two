# frozen_string_literal: true

class CartItemsController < ApplicationController
  def create
    listing = Listing.with_card_includes.friendly.find(params[:listing_id])
    cart = persistent_cart
    authorize cart, :update?

    result = Carts::AddItem.new(cart: cart,
                                listing: listing,
                                quantity: quantity_param,
                                offer: offer_param).call

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
    result = Carts::UpdateItem.new(item: item, quantity: quantity_param).call

    if result.success?
      notice = result.removed ? t("cart.flash.removed") : t("cart.flash.updated")
      redirect_to cart_path, notice: notice
    else
      redirect_to cart_path, alert: result.errors.first
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

  def offer_param
    return if params[:offer_id].blank?

    raise ActiveRecord::RecordNotFound unless Flipper.enabled?(:offers)

    Offer.find(params[:offer_id])
  end

  def buy_now?
    ActiveModel::Type::Boolean.new.cast(params[:buy_now])
  end
end
