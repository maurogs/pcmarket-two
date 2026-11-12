# frozen_string_literal: true

module NotificationsHelper
  include MoneyHelper

  def notification_message(notification)
    params = notification.params.to_h.symbolize_keys
    params[:price] = money(params.delete(:price_cents), currency: params[:currency]) if params.key?(:price_cents)
    params[:amount] = money(params.delete(:total_cents), currency: params[:currency]) if params.key?(:total_cents)

    t("notifications.messages.#{notification.kind}", **params, raise: true)
  rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument
    t("notifications.messages.default")
  end

  def notification_path(notification)
    case notification.notifiable
    when Listing then listing_path(notification.notifiable)
    when Order then order_path(notification.notifiable)
    else notifications_path
    end
  rescue ActionController::UrlGenerationError
    notifications_path
  end

  def notification_unread?(notification)
    notification.read_at.nil?
  end
end
