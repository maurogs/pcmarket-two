# frozen_string_literal: true

module Api
  module V1
    class MessagesController < AuthenticatedController
      def index
        conversation = Conversation.for_user(current_user).find(params[:conversation_id])
        authorize conversation

        records, meta = cursor_page(
          conversation.messages.visible.includes({ sender: { avatar_attachment: :blob } }, images_attachments: :blob)
        )
        render_collection(records, MessageSerializer, meta: meta)
      end

      def create
        conversation = Conversation.for_user(current_user).find(params[:conversation_id])
        message = conversation.messages.new(
          body: params.dig(:message, :body) || params[:body],
          sender: current_user
        )
        authorize message

        attach_images(message)
        message.save!
        render_resource(message, MessageSerializer, status: :created)
      end

      private

      def attach_images(message)
        signed_ids = params.dig(:message, :image_signed_ids) || params[:image_signed_ids]
        Array(signed_ids).compact_blank.each do |signed_id|
          blob = ActiveStorage::Blob.find_signed!(signed_id)
          message.images.attach(blob)
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          raise Api::V1::Error.validation_failed(
            details: { images: [ I18n.t("api.errors.invalid_signed_id", locale: error_locale) ] }
          )
        end
      end
    end
  end
end
