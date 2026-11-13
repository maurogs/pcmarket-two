# frozen_string_literal: true

class NotificationReadsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.notifications.unread.update_all(read_at: Time.current)
    Notification.expire_unread_cache(current_user)
    Notification.broadcast_bell(current_user)

    redirect_back fallback_location: notifications_path,
                  notice: t("notifications.flash.all_read")
  end
end
