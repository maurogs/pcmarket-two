# frozen_string_literal: true

class CartItem < ApplicationRecord
  belongs_to :cart, touch: true
  belongs_to :listing

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :listing_id, uniqueness: { scope: :cart_id }
  validate :listing_is_not_owned_by_buyer
  validate :listing_is_purchasable, on: :create

  def line_total_cents
    listing.price_cents.to_i * quantity
  end

  def purchasable?
    listing.published? &&
      listing.quantity.to_i >= quantity &&
      listing.store&.active? &&
      listing.store.payouts_ready? &&
      !listing.store.vacation_mode? &&
      !listing.seller.banned? &&
      !listing.seller.soft_deleted? &&
      !own_listing?
  end

  def own_listing?
    cart.user_id.present? && listing.user_id == cart.user_id
  end

  def unavailable_reason
    return :own_listing if own_listing?
    return :store_vacation if listing.store&.vacation_mode?
    return :payouts_not_enabled unless listing.store&.payouts_ready?
    return :out_of_stock if listing.published? && listing.quantity.to_i < quantity
    return :out_of_stock if listing.quantity.to_i.zero?
    return :unavailable unless listing.published? && listing.store&.active?
    return :unavailable if listing.seller.banned? || listing.seller.soft_deleted?

    nil
  end

  private

  def listing_is_not_owned_by_buyer
    return unless cart&.user_id.present? && listing&.user_id == cart.user_id

    errors.add(:listing, I18n.t("cart.errors.own_listing"))
  end

  def listing_is_purchasable
    return if listing.blank?

    unless listing.published? && listing.quantity.to_i.positive? && listing.store&.active?
      errors.add(:listing, I18n.t("cart.errors.unavailable"))
      return
    end

    return unless listing.store.vacation_mode?

    errors.add(:listing, I18n.t("cart.errors.store_vacation"))
  end
end
