# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < AuthenticatedController
      def index
        scope = current_user.notifications.includes(:notifiable)
        records, meta = cursor_page(scope)
        render_collection(records, NotificationSerializer, meta: meta)
      end
    end
  end
end
