# frozen_string_literal: true

module Api
  module V1
    class NotificationSerializer < BaseSerializer
      attributes :id, :kind, :notifiable_type, :notifiable_id, :params,
                 :read_at, :created_at

      attribute :message do |notification|
        values = notification.params.to_h.symbolize_keys
        values[:price] = money(values.delete(:price_cents), values[:currency]) if values.key?(:price_cents)
        values[:amount] = money(values.delete(:total_cents), values[:currency]) if values.key?(:total_cents)
        values[:amount] = money(values.delete(:amount_cents), values[:currency]) if values.key?(:amount_cents)
        I18n.t("notifications.messages.#{notification.kind}", **values)
      rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument
        I18n.t("notifications.messages.default")
      end

      attribute :unread do |notification|
        notification.read_at.nil?
      end
    end
  end
end
