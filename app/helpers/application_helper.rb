# frozen_string_literal: true

module ApplicationHelper
  include MoneyHelper

  def cart_badge_count
    cart = current_cart
    return 0 if cart.blank?

    cart.persisted? ? cart.cached_item_count : 0
  end

  # Memoised once per request, so cards never issue a query each.
  def favourited_listing_ids
    @favourited_listing_ids ||= if user_signed_in?
      current_user.favourites.pluck(:listing_id).to_set
    else
      Set.new
    end
  end

  def favourited?(listing)
    return false if listing.blank?

    favourited_listing_ids.include?(listing.id)
  end

  def followed_store_ids
    @followed_store_ids ||= if user_signed_in?
      current_user.follows.pluck(:store_id).to_set
    else
      Set.new
    end
  end

  def following?(store)
    return false if store.blank?

    followed_store_ids.include?(store.id)
  end

  # Matches the target id emitted by the Turbo Stream replace response.
  def favourite_dom_id(listing)
    ActionView::RecordIdentifier.dom_id(listing, :favourite)
  end
end
