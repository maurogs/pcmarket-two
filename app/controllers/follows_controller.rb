# frozen_string_literal: true

class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store

  def create
    authorize Follow.new(follower: current_user, store: @store)
    current_user.follows.find_or_create_by!(store: @store)
    redirect_back fallback_location: wishlist_path(tab: "following"),
                  notice: t("follows.flash.followed")
  end

  def destroy
    follow = current_user.follows.find_by!(store: @store)
    authorize follow
    follow.destroy!
    redirect_back fallback_location: wishlist_path(tab: "following"),
                  notice: t("follows.flash.unfollowed")
  end

  private

  def set_store
    @store = Store.friendly.find(params[:store_id])
  end
end
