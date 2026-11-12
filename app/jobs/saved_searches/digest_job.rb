# frozen_string_literal: true

module SavedSearches
  class DigestJob < ApplicationJob
    queue_as :default

    def perform
      SavedSearches::Digester.new.call
    end
  end
end
