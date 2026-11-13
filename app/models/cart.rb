# frozen_string_literal: true

class Cart < ApplicationRecord
  # One shipping charge per seller (the most expensive line).
  Group = Struct.new(:store, :items, :shipping_cents, keyword_init: true) do
    def subtotal_cents
      items.sum(&:line_total_cents)
    end

    def total_cents
      subtotal_cents + shipping_cents
    end
  end

  belongs_to :user, optional: true
  has_many :items, class_name: "CartItem", dependent: :destroy, inverse_of: :cart

  before_validation :generate_token, on: :create

  validates :token, presence: true, uniqueness: true, if: :guest?
  validates :user_id, uniqueness: true, allow_nil: true

  scope :guest, -> { where(user_id: nil) }

  def guest?
    user_id.nil?
  end

  def item_count
    items.sum(:quantity)
  end

  def cached_item_count
    Rails.cache.fetch([ "carts", id, updated_at.to_f, "item_count" ]) { item_count }
  end

  def available_items
    items
      .includes(:offer, listing: [ :store, :seller, { photos: { image_attachment: :blob } } ])
      .select(&:purchasable?)
  end

  def unavailable_items
    items
      .includes(:offer, listing: [ :store, :seller, { photos: { image_attachment: :blob } } ])
      .reject(&:purchasable?)
  end

  def groups(listing_id: nil)
    items = available_items
    items = items.select { |item| item.listing_id == listing_id.to_i } if listing_id.present?

    items.group_by { |item| item.listing.store }.map do |store, items|
      shipping = items.map { |item| item.listing.free_shipping? ? 0 : item.listing.shipping_price_cents.to_i }.max.to_i
      Group.new(store: store, items: items, shipping_cents: shipping)
    end
  end

  def subtotal_cents
    groups.sum(&:subtotal_cents)
  end

  def shipping_cents
    groups.sum(&:shipping_cents)
  end

  def total_cents
    subtotal_cents + shipping_cents
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(24) if user_id.nil?
  end
end
