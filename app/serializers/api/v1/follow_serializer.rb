# frozen_string_literal: true

module Api
  module V1
    class FollowSerializer < BaseSerializer
      attributes :id, :store_id, :last_notified_at, :created_at

      attribute :store do |follow|
        StoreSummarySerializer.new(follow.store).serializable_hash
      end
    end
  end
end
