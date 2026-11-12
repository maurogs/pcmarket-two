# frozen_string_literal: true

module Api
  module V1
    class SavedSearchSerializer < BaseSerializer
      attributes :id, :name, :category_id, :query_params, :frequency,
                 :email_alerts, :last_notified_at, :created_at, :updated_at

      attribute :suggested_name do |saved_search|
        params[:suggested_names].is_a?(Hash) ? params[:suggested_names][saved_search.id] : nil
      end
    end
  end
end
