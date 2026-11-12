# frozen_string_literal: true

class StorefrontsController < ApplicationController
  def show
    @store = Store.active.friendly.find(params[:id])
    @listings = Listing.visible.where(store_id: @store.id)
                      .with_card_includes
                      .order(published_at: :desc, id: :desc)
                      .limit(24)
  end
end
