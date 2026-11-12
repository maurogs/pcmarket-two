# frozen_string_literal: true

# Whitelists the top-level listing search params before they reach
# ListingSearch. Unknown keys never leave the controller, and the query object
# only accepts spec keys that belong to the current category.
module ListingFilters
  extend ActiveSupport::Concern

  SEARCH_PARAM_KEYS = %w[
    q category min_price max_price condition specs tags region
    free_shipping sort page
  ].freeze

  private

  def listing_search_params
    params.to_unsafe_h.slice(*SEARCH_PARAM_KEYS)
  end

  def cache_public_results
    return if user_signed_in?

    response.headers["Cache-Control"] = "public, max-age=60"
  end
end
