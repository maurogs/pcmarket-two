# frozen_string_literal: true

class StorefrontsController < ApplicationController
  def show
    @store = Store.active.friendly.find(params[:id])
    @profile = StorefrontProfile.new(store: @store, params: request.query_parameters).call
    @search = @profile.search

    response.headers["Cache-Control"] = "public, max-age=60" unless user_signed_in?
  end
end
