# frozen_string_literal: true

module Admin
  # Base policy for the staff area. Moderators may moderate listings; every
  # other admin screen is admin-only.
  class ApplicationPolicy < ::ApplicationPolicy
    def admin?
      user.present? && user.admin?
    end

    def moderator?
      user.present? && user.moderator?
    end

    def staff?
      admin? || moderator?
    end
  end
end
