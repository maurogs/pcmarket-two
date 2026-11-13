# frozen_string_literal: true

module Admin
  class UserPolicy < ApplicationPolicy
    def index?
      staff?
    end

    def show?
      staff?
    end

    def edit?
      admin?
    end

    def update?
      admin?
    end

    def ban?
      admin?
    end

    def unban?
      admin?
    end

    def change_role?
      admin?
    end

    def confirm?
      admin?
    end

    def resend_confirmation?
      admin?
    end

    def reset_password?
      admin?
    end

    def destroy?
      admin?
    end

    def impersonate?
      admin?
    end
  end
end
