# frozen_string_literal: true

class SavedSearchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_saved_search, only: %i[update destroy]

  def index
    authorize SavedSearch
    @saved_searches = policy_scope(SavedSearch)
                      .includes(:category)
                      .order(created_at: :desc)
  end

  def create
    @saved_search = current_user.saved_searches.new(saved_search_params)
    authorize @saved_search

    if @saved_search.save
      redirect_back fallback_location: saved_searches_path,
                    notice: t("saved_searches.flash.created")
    else
      redirect_back fallback_location: saved_searches_path,
                    alert: @saved_search.errors.full_messages.first
    end
  end

  def update
    authorize @saved_search

    if @saved_search.update(saved_search_params)
      redirect_back fallback_location: saved_searches_path,
                    notice: t("saved_searches.flash.updated")
    else
      redirect_back fallback_location: saved_searches_path,
                    alert: @saved_search.errors.full_messages.first
    end
  end

  def destroy
    authorize @saved_search
    @saved_search.destroy!
    redirect_back fallback_location: saved_searches_path,
                  notice: t("saved_searches.flash.destroyed")
  end

  private

  def set_saved_search
    @saved_search = policy_scope(SavedSearch).find(params[:id])
  end

  def saved_search_params
    permitted = params.require(:saved_search)
                      .permit(:name, :category_id, :email_alerts, :frequency)
    raw_query = params.dig(:saved_search, :query_params_json)
    permitted[:query_params] = parsed_query_params(raw_query) if raw_query.present?
    permitted
  end

  # The search page sends its normalised filters as a hidden JSON string; it is
  # parsed here (never trusted further) and the model applies its own whitelist.
  def parsed_query_params(raw)
    return raw if raw.is_a?(Hash)
    return {} unless raw.is_a?(String)

    parsed = JSON.parse(raw)
    parsed.is_a?(Hash) ? parsed : {}
  rescue StandardError
    {}
  end
end
