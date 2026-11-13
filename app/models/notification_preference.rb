# frozen_string_literal: true

class NotificationPreference < ApplicationRecord
  KINDS = Notification::KINDS

  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :kind, uniqueness: { scope: :user_id }

  def self.defaults_for(_kind)
    { in_app: true, email: true }
  end

  # Returns an existing preference or an unsaved record with the defaults.
  # Accepts a preloaded array/hash so batch jobs can avoid N+1 queries.
  def self.for(user:, kind:, preferences: nil)
    kind = kind.to_s
    existing = if preferences
      if preferences.is_a?(Hash)
        preferences[kind] || preferences[kind.to_sym]
      else
        Array(preferences).find { |preference| preference.kind.to_s == kind }
      end
    else
      user.notification_preferences.find_by(kind: kind)
    end

    existing || new(user: user, kind: kind, **defaults_for(kind))
  end

  def self.settings_for(user)
    preferences = user.notification_preferences.to_a.index_by { |preference| preference.kind.to_s }
    KINDS.index_with do |kind|
      preferences[kind.to_s] || new(user: user, kind: kind.to_s, **defaults_for(kind))
    end
  end

  def self.in_app?(user, kind, preferences: nil)
    return true if user.blank?

    self.for(user: user, kind: kind, preferences: preferences).in_app?
  end

  def self.email?(user, kind, preferences: nil)
    return false if user.blank?

    kind = kind.to_s
    if marketing_kind?(kind)
      return false unless user.respond_to?(:marketing_opt_in?) && user.marketing_opt_in?
    end

    self.for(user: user, kind: kind, preferences: preferences).email?
  end

  def self.marketing_kind?(kind)
    Notification::MARKETING_KINDS.include?(kind.to_s)
  end
end
