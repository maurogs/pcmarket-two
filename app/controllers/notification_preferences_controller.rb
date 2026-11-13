# frozen_string_literal: true

class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize NotificationPreference.new(user: current_user)
    @preferences = NotificationPreference.settings_for(current_user)
  end

  def update
    authorize NotificationPreference.new(user: current_user)
    persist_preferences
    update_marketing
    redirect_to notification_preferences_path,
                notice: t("notifications.preferences.flash.updated")
  end

  private

  def persist_preferences
    submitted = params[:notification_preferences]
    return unless submitted.respond_to?(:each_pair)

    NotificationPreference.transaction do
      submitted.each_pair do |kind, values|
        next unless Notification::KINDS.include?(kind.to_s)
        next unless values.respond_to?(:key?)

        preference = current_user.notification_preferences
                                 .find_or_initialize_by(kind: kind.to_s)
        preference.in_app = boolean_preference(values, :in_app)
        preference.email = boolean_preference(values, :email)
        preference.save!
      end
    end
  end

  def update_marketing
    return unless params.key?(:marketing_opt_in)

    raw = params[:marketing_opt_in]
    raw = raw.last if raw.is_a?(Array)
    current_user.update(marketing_opt_in: ActiveModel::Type::Boolean.new.cast(raw))
  end

  # A hidden "0" preceding each checkbox means unchecked arrives as "0" and
  # checked as ["0", "1"]. Missing keys keep the enabled-by-default behaviour.
  def boolean_preference(values, key)
    raw = values[key.to_s]
    raw = raw.last if raw.is_a?(Array)
    return true if raw.nil?

    ActiveModel::Type::Boolean.new.cast(raw)
  end
end
