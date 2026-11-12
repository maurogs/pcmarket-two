# frozen_string_literal: true

class CategoriesController < ApplicationController
  include ListingFilters

  def show
    @category = Category.active.friendly.find(params[:id])

    if @category.slug != params[:id]
      redirect_to category_path(@category), status: :moved_permanently
      return
    end

    @search = ListingSearch.new(listing_search_params, category: @category).call
    cache_public_results
    render "listings/index"
  end
end
