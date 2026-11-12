# frozen_string_literal: true

module Api
  module V1
    class ConversationReadsController < AuthenticatedController
      def create
        conversation = Conversation.for_user(current_user).find(params[:conversation_id])
        authorize conversation, :show?
        count = conversation.mark_read_for!(current_user)

        render_data({
          conversation_id: conversation.id,
          marked_read: count,
          unread_count: conversation.unread_count_for(current_user)
        })
      end
    end
  end
end
