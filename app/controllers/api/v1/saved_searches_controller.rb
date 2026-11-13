# frozen_string_literal: true

module Api
  module V1
    class SavedSearchesController < AuthenticatedController
      before_action :set_saved_search, only: %i[update destroy]

      def index
        authorize SavedSearch
        collection_response(
          policy_scope(SavedSearch).includes(:category).order(created_at: :desc),
          SavedSearchSerializer
        )
      end

      def create
        saved_search = current_user.saved_searches.new(saved_search_params)
        authorize saved_search
        saved_search.save!
        render_resource(saved_search, SavedSearchSerializer, status: :created)
      end

      def update
        authorize @saved_search
        @saved_search.update!(saved_search_params)
        render_resource(@saved_search, SavedSearchSerializer)
      end

      def destroy
        authorize @saved_search
        @saved_search.destroy!
        head :no_content
      end

      private

      def set_saved_search
        @saved_search = policy_scope(SavedSearch).find(params[:id])
      end

      def saved_search_params
        permitted = params.require(:saved_search)
                          .permit(:name, :category_id, :email_alerts, :frequency)
        raw = params.dig(:saved_search, :query_params)
        if raw.present?
          permitted[:query_params] = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw
        end
        permitted
      end
    end
  end
end
