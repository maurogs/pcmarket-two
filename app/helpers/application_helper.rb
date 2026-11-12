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

  # Cookie consent: "necessary" is always on. The consent cookie itself is a
  # necessary first-party cookie.
  def cookie_consent_categories
    @cookie_consent_categories ||= CookieConsent.categories_from_cookie(
      cookies[CookieConsent::COOKIE_NAME]
    )
  end

  def cookie_consent_given?
    cookies[CookieConsent::COOKIE_NAME].present?
  end

  def consented_to?(category)
    cookie_consent_categories[category.to_s] == true
  end

  # The footer only advertises the credits page when demo photos are attached,
  # so a clean production install never links to an empty page.
  def demo_image_credits?
    Demo::ImageCredits.any?
  rescue StandardError
    false
  end

  # Memoised seller store for the header/account menu. Avoids loading the same
  # association twice per request on onboarding screens.
  def current_user_store
    return unless user_signed_in?

    @current_user_store ||= Store.find_by(user_id: current_user.id)
  end
end
