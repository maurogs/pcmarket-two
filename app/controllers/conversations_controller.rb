# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize Conversation
    @inbox = Inbox.new(user: current_user, params: params).call
  end

  def show
    @conversation = current_user_conversations.find(params[:id])
    authorize @conversation
    @conversation.mark_read_for!(current_user)
    @messages = @conversation.messages.visible
                               .includes(:sender, images_attachments: :blob)
    @offers = @conversation.offers.recent.includes(:offerer)
    @message = Message.new
  end

  def create
    authorize Conversation
    result = Conversations::FindOrCreate.new(
      buyer: current_user,
      listing: listing_param,
      store: store_param
    ).call

    if result.success?
      redirect_to conversation_path(result.conversation), notice: t("conversations.flash.opened")
    else
      redirect_back fallback_location: root_path, alert: result.errors.first
    end
  end

  private

  def current_user_conversations
    Conversation.for_user(current_user)
  end

  def listing_param
    return if params[:listing_id].blank?

    Listing.find(params[:listing_id])
  end

  def store_param
    return if params[:store_id].blank?

    Store.friendly.find(params[:store_id])
  end
end
