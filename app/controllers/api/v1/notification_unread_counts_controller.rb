# frozen_string_literal: true

module Api
  module V1
    class NotificationUnreadCountsController < AuthenticatedController
      def show
        render_data({ unread_count: Notification.unread_count_for(current_user) })
      end
    end
  end
end
