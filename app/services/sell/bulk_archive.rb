# frozen_string_literal: true

module Sell
  # Archives a batch of listings owned by one seller. Ids belonging to other
  # sellers are silently ignored, and only listings the state machine allows to
  # be archived are touched.
  class BulkArchive
    def initialize(user:, ids:)
      @user = user
      @ids = ids
    end

    def call
      ids = normalized_ids
      return 0 if ids.empty?

      archived = 0
      @user.listings.where(id: ids).find_each do |listing|
        next unless listing.may_archive?

        listing.archive!
        archived += 1
      end
      archived
    end

    private

    def normalized_ids
      Array(@ids).map(&:to_s).reject(&:empty?).uniq
    end
  end
end
