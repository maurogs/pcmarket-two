# frozen_string_literal: true

module Api
  module V1
    class BlocksController < AuthenticatedController
      def index
        collection_response(
          current_user.blocks.includes(blocked: { avatar_attachment: :blob }).order(created_at: :desc),
          BlockedUserSerializer
        )
      end

      def create
        block = current_user.blocks.new(
          blocked_id: params[:blocked_user_id] || params[:blocked_id]
        )
        authorize block
        block.save!
        render_resource(block, BlockedUserSerializer, status: :created)
      end

      def destroy
        block = current_user.blocks.find(params[:id])
        authorize block
        block.destroy!
        head :no_content
      end
    end
  end
end
