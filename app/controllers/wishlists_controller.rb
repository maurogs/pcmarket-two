# frozen_string_literal: true

class WishlistsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :wishlist, :show?
    @wishlist = Wishlist.new(user: current_user, params: params).call
  end
end
