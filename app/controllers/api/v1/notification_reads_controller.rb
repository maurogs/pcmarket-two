# frozen_string_literal: true

module Api
  module V1
    class NotificationReadsController < AuthenticatedController
      def create
        notification = current_user.notifications.find(params[:notification_id])
        authorize notification, :update?
        notification.mark_read!
        render_resource(notification, NotificationSerializer)
      end
    end
  end
end
