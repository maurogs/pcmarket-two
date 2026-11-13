# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end
end
