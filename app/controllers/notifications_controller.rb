# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize Notification
    @inbox = NotificationInbox.new(user: current_user, params: params).call
  end
end
