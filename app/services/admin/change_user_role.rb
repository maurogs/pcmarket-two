# frozen_string_literal: true

module Admin
  # Role changes with the two safety rules requested by the brief: an admin
  # cannot demote themselves and at least one admin must always remain.
  class ChangeUserRole
    def initialize(user:, actor:, role:)
      @user = user
      @actor = actor
      @role = role.to_s
    end

    def call
      return false unless User.roles.key?(@role)
      return false if demoting_self?
      return false if removing_last_admin?

      @user.update!(role: @role)
      true
    end

    private

    def demoting_self?
      @user.id == @actor.id && @role != "admin"
    end

    def removing_last_admin?
      return false unless @user.admin? && @role != "admin"

      User.where(role: User.roles[:admin]).where.not(id: @user.id).none?
    end
  end
end
