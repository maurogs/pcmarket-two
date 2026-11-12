# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @conversation = Conversation.for_user(current_user).find(params[:conversation_id])
    @message = @conversation.messages.new(message_params.merge(sender: current_user))
    authorize @message

    if @message.save
      respond_to do |format|
        format.turbo_stream { render_composer }
        format.html { redirect_to conversation_path(@conversation), notice: t("messages.flash.sent") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_composer(status: :unprocessable_entity) }
        format.html { redirect_to conversation_path(@conversation), alert: @message.errors.full_messages.first }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:body, images: [])
  end

  def render_composer(status: :ok)
    render turbo_stream: turbo_stream.replace(
      "message-composer",
      partial: "conversations/composer",
      locals: { conversation: @conversation, message: status == :ok ? Message.new : @message }
    ), status: status
  end
end
