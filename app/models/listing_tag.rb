# frozen_string_literal: true

class ListingTag < ApplicationRecord
  belongs_to :listing
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :listing_id }
end
