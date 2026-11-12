# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  extend Mobility

  translates :name

  friendly_id :slug_source, use: :slugged

  enum :kind, { product_label: 0, seller_tag: 1 }, scopes: false

  # Tailwind component colour tokens available to product labels and seller
  # tags. The admin form renders a live preview for the selected token.
  COLOURS = %w[accent primary success warning danger neutral].freeze

  has_many :listing_tags, dependent: :destroy
  has_many :listings, through: :listing_tags

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :kind }
  validates :colour, inclusion: { in: COLOURS }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }
  scope :product_labels, -> { where(kind: :product_label) }
  scope :seller_tags, -> { where(kind: :seller_tag) }

  def slug_source
    name_en.presence || name_es.presence || name
  end
end
