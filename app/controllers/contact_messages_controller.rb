# frozen_string_literal: true

class ContactMessagesController < ApplicationController
  def index
    @contact_message = ContactMessage.new(topic: ContactMessage::TOPICS.first)
  end

  def create
    @contact_message = ContactMessage.new(
      contact_message_params.merge(website: params[:website])
    )

    if @contact_message.spam?
      redirect_to contact_messages_path, notice: t("contact.flash.sent")
    elsif @contact_message.save
      ContactMailer.notification(@contact_message).deliver_later
      redirect_to contact_messages_path, notice: t("contact.flash.sent")
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message)
          .permit(:name, :email, :topic, :order_number, :message)
  end
end
