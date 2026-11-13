# frozen_string_literal: true

class InboxReadsController < ApplicationController
  before_action :authenticate_user!

  def create
    authorize Conversation, :index?

    Conversation.for_user(current_user).find_each do |conversation|
      conversation.mark_read_for!(current_user)
    end

    redirect_to conversations_path, notice: t("conversations.flash.all_read")
  end
end
