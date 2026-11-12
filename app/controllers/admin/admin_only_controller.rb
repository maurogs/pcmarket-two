# frozen_string_literal: true

module Admin
  # Sections that only administrators may reach. Moderators get a 404 (they
  # already pass Admin::BaseController's staff check), matching the contract
  # used by the public admin area.
  class AdminOnlyController < BaseController
    before_action :require_admin

    private

    def require_admin
      head :not_found unless current_user&.admin?
    end
  end
end
