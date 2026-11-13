# frozen_string_literal: true

module Reviews
  # Reminds a buyer to review a delivered order. Scheduled three days after
  # delivery confirmation and skipped when a review already exists.
  class ReminderJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = Order.includes(:review, :store, :checkout, :buyer).find_by(id: order_id)
      return if order.blank?
      return if order.review.present?
      return unless order.delivered? || order.completed?
      return if order.delivered_at.blank? || order.delivered_at > 3.days.ago
      return if order.buyer.blank? || order.buyer.soft_deleted?

      ReviewMailer.reminder(order).deliver_later
    end
  end
end
