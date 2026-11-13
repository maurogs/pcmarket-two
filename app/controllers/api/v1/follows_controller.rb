# frozen_string_literal: true

module Api
  module V1
    class FollowsController < AuthenticatedController
      def index
        wishlist = Wishlist.new(user: current_user, params: { tab: "following" }).call
        pagy, records = paginate_array(wishlist.follows)
        set_pagination_headers(pagy)
        render_collection(records, FollowSerializer, meta: collection_meta(pagy))
      end

      def create
        store = Store.friendly.find(params[:store_id])
        follow = Follow.new(follower: current_user, store: store)
        authorize follow

        follow = current_user.follows.find_or_create_by!(store: store)
        render_resource(follow, FollowSerializer, status: :created)
      end

      def destroy
        follow = current_user.follows.find(params[:id])
        authorize follow
        follow.destroy!
        head :no_content
      end
    end
  end
end
