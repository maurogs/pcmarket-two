# frozen_string_literal: true

module Api
  module V1
    class ApiSessionSerializer < BaseSerializer
      attributes :id, :device_name, :platform, :app_version,
                 :last_used_at, :expires_at, :refresh_expires_at,
                 :revoked_at, :ip, :created_at

      attribute :current do |session|
        params[:current_session_id].present? && session.id == params[:current_session_id]
      end
    end
  end
end
