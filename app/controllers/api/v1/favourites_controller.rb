# frozen_string_literal: true

module Api
  module V1
    class FavouritesController < AuthenticatedController
      def index
        wishlist = Wishlist.new(user: current_user, params: { tab: "favourites" }).call
        pagy, records = paginate_array(wishlist.favourites)
        set_pagination_headers(pagy)
        render_collection(records, FavouriteSerializer, meta: collection_meta(pagy))
      end

      def create
        listing = Listing.friendly.find(params[:listing_id])
        authorize Favourite.new(user: current_user, listing: listing)

        favourite = current_user.favourites.find_or_create_by!(listing: listing)
        render_resource(favourite, FavouriteSerializer, status: :created)
      end

      def destroy
        favourite = current_user.favourites.find(params[:id])
        authorize favourite
        favourite.destroy!
        head :no_content
      end
    end
  end
end
