# frozen_string_literal: true

module Api
  module V1
    class StoresController < BaseController
      def show
        store = Store.active.includes(:user).friendly.find(params[:id])
        cache_public_catalogue!
        return if conditional_get!(etag: [ store, I18n.locale ],
                                   last_modified: store.updated_at,
                                   public: current_user.nil?)

        render_resource(store, StoreDetailSerializer)
      end
    end
  end
end
