# frozen_string_literal: true

class CartsController < ApplicationController
  def show
    @cart = current_cart
    authorize @cart
    @groups = @cart.persisted? ? @cart.groups : []
  end
end
