# frozen_string_literal: true

module Api
  module V1
    class ReviewSerializer < BaseSerializer
      attributes :id, :order_id, :store_id, :rating, :body, :status,
                 :seller_reply, :seller_replied_at, :created_at, :updated_at

      attribute :reviewer do |review|
        UserSummarySerializer.new(review.reviewer).serializable_hash
      end

      attribute :editable do |review|
        review.editable?
      end
    end
  end
end
