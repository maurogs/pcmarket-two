# frozen_string_literal: true

# Immutable trail of every staff mutation performed from the admin panel.
class AdminAuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true

  # `changes` is reserved by Active Record, so the column is stored as
  # `changes_data` and exposed through the domain-facing name.
  def changes
    changes_data
  end

  def changes=(value)
    self.changes_data = value
  end

  validates :action, presence: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def self.record!(actor:, action:, auditable:, changes: {}, ip: nil, user_agent: nil)
    create!(
      actor: actor,
      action: action,
      auditable: auditable,
      changes: changes.presence || {},
      ip: ip,
      user_agent: user_agent
    )
  end
end
