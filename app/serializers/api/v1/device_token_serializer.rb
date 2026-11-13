# frozen_string_literal: true

module Api
  module V1
    class DeviceTokenSerializer < BaseSerializer
      attributes :id, :platform, :token, :last_seen_at, :created_at, :updated_at
    end
  end
end
