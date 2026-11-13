# frozen_string_literal: true

module Api
  module V1
    class NotificationReadAllsController < AuthenticatedController
      def create
        count = current_user.notifications.unread.update_all(read_at: Time.current)
        Notification.expire_unread_cache(current_user)
        Notification.broadcast_bell(current_user)

        render_data({ marked_read: count, unread_count: 0 })
      end
    end
  end
end
