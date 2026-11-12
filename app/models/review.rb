# frozen_string_literal: true

class Review < ApplicationRecord
  REVIEW_WINDOW = 60.days
  EDIT_WINDOW = 7.days

  belongs_to :order
  belongs_to :reviewer, class_name: "User"
  belongs_to :store

  enum :status, { visible: 0, hidden: 1 }, scopes: false

  validates :rating, inclusion: { in: 1..5 }
  validates :body, presence: true, length: { in: 10..2000 }
  validates :order_id, uniqueness: true
  validates :seller_reply, length: { maximum: 2000 }, allow_blank: true
  validate :reviewer_is_buyer
  validate :store_matches_order
  validate :order_is_reviewable, on: :create

  scope :visible_reviews, -> { where(status: :visible) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :highest_first, -> { order(rating: :desc, created_at: :desc, id: :desc) }
  scope :lowest_first, -> { order(rating: :asc, created_at: :desc, id: :desc) }
  scope :with_reviewer, -> { includes(reviewer: { avatar_attachment: :blob }) }

  after_commit :refresh_store_rating

  def self.sorted_by(key)
    case key.to_s
    when "highest" then highest_first
    when "lowest" then lowest_first
    else newest_first
    end
  end

  def editable?
    created_at.present? && created_at >= EDIT_WINDOW.ago
  end

  def seller_replied?
    seller_reply.present?
  end

  def replyable_by?(user)
    user.present? && store.user_id == user.id && !seller_replied?
  end

  def reviewer_name
    reviewer&.soft_deleted? ? I18n.t("users.deleted") : reviewer&.display_name
  end

  private

  def reviewer_is_buyer
    return if order.blank? || reviewer.blank?
    return if order.buyer_id == reviewer_id

    errors.add(:reviewer, I18n.t("reviews.errors.not_buyer"))
  end

  def store_matches_order
    return if order.blank? || store.blank?
    return if order.store_id == store_id

    errors.add(:store, I18n.t("reviews.errors.wrong_store"))
  end

  def order_is_reviewable
    return if order.blank?

    unless order.delivered? || order.completed?
      errors.add(:order, I18n.t("reviews.errors.not_delivered"))
      return
    end

    return if order.delivered_at.present? && order.delivered_at >= REVIEW_WINDOW.ago

    errors.add(:order, I18n.t("reviews.errors.window_closed"))
  end

  # One aggregate query for the average and count, then one update. The
  # updated_at bump invalidates cached storefront fragments.
  def refresh_store_rating
    average, count = self.class.visible_reviews.where(store_id: store_id)
                           .pick(Arel.sql("AVG(rating)"), Arel.sql("COUNT(*)"))
    Store.where(id: store_id).update_all(
      rating_average: average.present? ? average.to_d.round(2) : 0,
      ratings_count: count.to_i,
      updated_at: Time.current
    )
  end
end
