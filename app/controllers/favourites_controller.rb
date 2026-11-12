# frozen_string_literal: true

class FavouritesController < ApplicationController
  before_action :set_listing
  before_action :require_user

  def create
    authorize Favourite.new(user: current_user, listing: @listing)
    current_user.favourites.find_or_create_by!(listing: @listing)
    respond_with_favourite(true)
  end

  def destroy
    favourite = current_user.favourites.find_by(listing: @listing)
    authorize(Favourite.new(user: current_user, listing: @listing)) if favourite.blank?
    favourite&.destroy!
    respond_with_favourite(false)
  end

  private

  def set_listing
    @listing = Listing.friendly.find(params[:listing_id])
  end

  # Devise redirects back here after sign in, for both HTML and Turbo posts.
  def require_user
    return if user_signed_in?

    store_location_for(:user, listing_path(@listing))
    redirect_to new_user_session_path
  end

  def respond_with_favourite(favourited)
    respond_to do |format|
      format.html do
        redirect_back fallback_location: listing_path(@listing),
                      notice: favourited ? t("favourites.flash.added") : t("favourites.flash.removed")
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.favourite_dom_id(@listing),
          partial: "favourites/button",
          locals: { listing: @listing, favourited: favourited }
        )
      end
    end
  end
end
