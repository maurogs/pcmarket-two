# frozen_string_literal: true

module Admin
  # Shared entry point for the staff-only area. Anonymous visitors are sent to
  # sign in by Devise; signed-in non-staff users must see a 404, never a 403,
  # so the area stays invisible to regular accounts.
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_staff

    private

    def require_staff
      return if current_user&.admin? || current_user&.moderator?

      raise ActiveRecord::RecordNotFound
    end
  end
end
