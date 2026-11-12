# frozen_string_literal: true

module Notifications
  # Delivery boundary for push notifications. The native apps register device
  # tokens today; sending is deliberately a no-op until the APNs and FCM
  # credentials exist.
  #
  # TODO: add APNs (Apple) and FCM (Google) adapters and choose the adapter by
  # platform/configuration. Call `deliver` from Notifications.record once the
  # adapters are available.
  class PushDelivery
    Adapter = Struct.new(:name, :callable, keyword_init: true) do
      def deliver(user:, device_tokens:, title:, body:, data: {})
        callable.call(user: user, device_tokens: device_tokens,
                      title: title, body: body, data: data)
      end
    end

    NOOP = Adapter.new(
      name: :noop,
      callable: lambda do |user:, device_tokens:, title:, body:, data:|
        Rails.logger.info(
          "[push:noop] user=#{user.id} tokens=#{device_tokens.size} " \
          "title=#{title.inspect} data=#{data.inspect}"
        )
        false
      end
    )

    class << self
      attr_writer :adapter

      def adapter
        @adapter ||= NOOP
      end

      def deliver(user:, title:, body:, data: {})
        return false if user.blank?

        tokens = user.device_tokens.to_a
        return false if tokens.empty?

        adapter.deliver(user: user, device_tokens: tokens, title: title,
                        body: body, data: data)
      end
    end
  end
end
