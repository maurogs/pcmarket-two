# frozen_string_literal: true

module Api
  module V1
    class BlockedUserSerializer < BaseSerializer
      attributes :id, :blocked_id, :created_at

      attribute :user do |block|
        UserSummarySerializer.new(block.blocked).serializable_hash
      end
    end
  end
end
