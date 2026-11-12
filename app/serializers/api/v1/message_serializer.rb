# frozen_string_literal: true

module Api
  module V1
    class MessageSerializer < BaseSerializer
      attributes :id, :conversation_id, :sender_id, :kind, :read_at,
                 :hidden_at, :safety_flagged, :created_at, :updated_at

      attribute :body do |message|
        localized_event_body(message)
      end

      attribute :raw_body do |message|
        message.body
      end

      attribute :metadata, &:metadata

      attribute :sender do |message|
        UserSummarySerializer.new(message.sender).serializable_hash
      end

      attribute :images do |message|
        message.images.map do |image|
          {
            thumb_url: attachment_url(image, variant: { resize_to_limit: [ 320, 320 ], format: :webp }),
            card_url: attachment_url(image, variant: { resize_to_limit: [ 1280, 1280 ], format: :webp }),
            original_url: Rails.application.routes.url_helpers.rails_blob_url(
              image, **BaseSerializer.image_url_options
            )
          }
        end
      end
    end
  end
end
