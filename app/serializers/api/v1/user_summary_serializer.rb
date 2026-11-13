# frozen_string_literal: true

module Api
  module V1
    class UserSummarySerializer < BaseSerializer
      attributes :id, :username, :role, :created_at

      attribute :display_name, &:display_name
      attribute :avatar_url do |user|
        attachment_url(user.avatar, variant: { resize_to_limit: [ 128, 128 ], format: :webp })
      end
      attribute :member_since do |user|
        timestamp(user.created_at)
      end
    end
  end
end
