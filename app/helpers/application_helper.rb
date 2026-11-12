module ApplicationHelper
  include MoneyHelper

  def cart_badge_count
    cart = current_cart
    return 0 if cart.blank?

    cart.persisted? ? cart.cached_item_count : 0
  end
end
