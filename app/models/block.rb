# frozen_string_literal: true

class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocked_id, uniqueness: { scope: :blocker_id }
  validate :not_self

  scope :involving, lambda { |user|
    where(blocker_id: user.id).or(where(blocked_id: user.id))
  }

  # All directed pairs involving the user in one query. Callers that render a
  # list of conversations use this instead of calling between? per row.
  def self.pairs_for(user)
    involving(user).pluck(:blocker_id, :blocked_id)
  end

  def self.between?(first, second)
    return false if first.blank? || second.blank?

    where(blocker_id: first.id, blocked_id: second.id)
      .or(where(blocker_id: second.id, blocked_id: first.id))
      .exists?
  end

  def self.blocked?(user, other)
    return false if user.blank? || other.blank?

    where(blocker_id: user.id, blocked_id: other.id).exists?
  end

  private

  def not_self
    return if blocker_id.blank? || blocked_id.blank?
    return if blocker_id != blocked_id

    errors.add(:blocked_id, I18n.t("blocks.errors.self"))
  end
end
