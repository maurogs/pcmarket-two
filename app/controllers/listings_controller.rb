# frozen_string_literal: true

class ListingsController < ApplicationController
  include ListingFilters

  def index
    @search = ListingSearch.new(listing_search_params).call
    @category = @search.category
    cache_public_results
  end

  def show
    @listing = Listing.with_detail_includes.friendly.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @listing.visible_to?(current_user)

    if @listing.slug != params[:id]
      redirect_to listing_path(@listing), status: :moved_permanently
      return
    end

    register_listing_view
    cache_listing_response
  end

  private

  def register_listing_view
    session_key = "listing_viewed/#{@listing.id}"
    return if session[session_key]

    @listing.update_column(:views_count, @listing.views_count + 1)
    session[session_key] = true
  end

  def cache_listing_response
    return if user_signed_in?

    fresh_when(
      etag: [ @listing, I18n.locale, current_user&.id ],
      last_modified: @listing.updated_at,
      public: true
    )
  end
end
