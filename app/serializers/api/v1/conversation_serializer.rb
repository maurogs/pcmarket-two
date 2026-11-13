# frozen_string_literal: true

module Api
  module V1
    class ConversationSerializer < BaseSerializer
      attributes :id, :listing_id, :buyer_id, :seller_id, :store_id,
                 :last_message_at, :created_at, :updated_at

      attribute :store do |conversation|
        StoreSummarySerializer.new(conversation.store).serializable_hash
      end

      attribute :buyer do |conversation|
        UserSummarySerializer.new(conversation.buyer).serializable_hash
      end

      attribute :seller do |conversation|
        UserSummarySerializer.new(conversation.seller).serializable_hash
      end

      attribute :unread_count do |conversation|
        params[:user] ? conversation.unread_count_for(params[:user]) : 0
      end

      attribute :archived do |conversation|
        params[:user] ? conversation.archived_for?(params[:user]) : false
      end

      attribute :title, &:display_title

      attribute :last_message do |conversation|
        message = conversation.messages.max_by { |candidate| [ candidate.created_at, candidate.id ] }
        message ? MessageSerializer.new(message).serializable_hash : nil
      end
    end
  end
end
