# frozen_string_literal: true

class BlocksController < ApplicationController
  before_action :authenticate_user!

  def create
    @block = current_user.blocks.new(blocked_id: params[:blocked_user_id])
    authorize @block

    if @block.save
      redirect_back fallback_location: root_path, notice: t("blocks.flash.created")
    else
      redirect_back fallback_location: root_path, alert: @block.errors.full_messages.first
    end
  end

  def destroy
    @block = current_user.blocks.find(params[:id])
    authorize @block
    @block.destroy!

    redirect_back fallback_location: root_path, notice: t("blocks.flash.destroyed")
  end
end
