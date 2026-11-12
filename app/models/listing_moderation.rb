# frozen_string_literal: true

class ListingModeration < ApplicationRecord
  belongs_to :listing
  belongs_to :moderator, class_name: "User"

  enum :action, {
    approved: 0,
    rejected: 1,
    archived: 2,
    restored: 3
  }, scopes: false

  validates :action, presence: true
end
