# frozen_string_literal: true

module SavedSearchesHelper
  def saved_search_frequency_label(frequency)
    t("saved_searches.frequency_options.#{frequency}")
  end
end
