# frozen_string_literal: true

require "set"

class Category < ApplicationRecord
  extend FriendlyId
  extend Mobility

  translates :name, :description, :seo_title, :seo_description

  TREE_CACHE_NAMESPACE = "categories/descendant_ids"

  belongs_to :parent, class_name: "Category", optional: true,
                      inverse_of: :children, touch: true

  has_many :children, class_name: "Category", foreign_key: :parent_id,
                      inverse_of: :parent, dependent: :restrict_with_error
  has_many :listings, dependent: :restrict_with_error
  has_many :category_attributes, dependent: :destroy
  has_many :attribute_definitions, through: :category_attributes

  friendly_id :slug_source, use: %i[slugged history]

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true }
  validate :parent_chain_has_no_cycle

  before_validation :assign_depth
  after_update :refresh_descendant_depths, if: :saved_change_to_parent_id?
  after_commit :bump_search_cache, if: :saved_change_to_active?

  scope :roots, -> { where(parent_id: nil).order(:position, :id) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  # Any category update changes the global maximum timestamp, which invalidates
  # every cached descendant list. `belongs_to :parent, touch: true` additionally
  # propagates the touch to ancestors.
  def self.tree_cache_version
    maximum(:updated_at)&.to_f
  end

  def self.descendant_ids_for(root_id)
    sql = <<~SQL
      WITH RECURSIVE category_tree AS (
        SELECT id FROM categories WHERE id = ?
        UNION
        SELECT categories.id FROM categories
        INNER JOIN category_tree ON categories.parent_id = category_tree.id
      )
      SELECT id FROM category_tree
    SQL

    connection.select_values(sanitize_sql_array([ sql, root_id ])).map(&:to_i)
  end

  def self.ancestor_ids_for(category_id)
    sql = <<~SQL
      WITH RECURSIVE category_tree AS (
        SELECT id, parent_id FROM categories WHERE id = ?
        UNION
        SELECT categories.id, categories.parent_id FROM categories
        INNER JOIN category_tree ON categories.id = category_tree.parent_id
      )
      SELECT id FROM category_tree WHERE id <> ?
    SQL

    connection.select_values(sanitize_sql_array([ sql, category_id, category_id ])).map(&:to_i)
  end

  # Depth is denormalised so sorting an ancestor list costs a single query.
  def self.refresh_depths_from(root_id)
    sql = <<~SQL
      WITH RECURSIVE category_tree AS (
        SELECT id, parent_id, depth FROM categories WHERE id = ?
        UNION ALL
        SELECT categories.id, categories.parent_id, category_tree.depth + 1
        FROM categories
        INNER JOIN category_tree ON categories.parent_id = category_tree.id
        WHERE category_tree.depth < 20
      )
      UPDATE categories
      SET depth = category_tree.depth
      FROM category_tree
      WHERE categories.id = category_tree.id
    SQL

    connection.execute(sanitize_sql_array([ sql, root_id ]))
  end

  def root?
    parent_id.nil?
  end

  def ancestor_ids
    return [] if new_record? || parent_id.nil?

    self.class.ancestor_ids_for(id)
  end

  def ancestors
    ids = ancestor_ids
    return [] if ids.empty?

    self.class.where(id: ids).order(:depth, :id).to_a
  end

  def breadcrumb
    ancestors + [ self ]
  end

  def descendant_ids
    return [] if new_record?

    Rails.cache.fetch([ TREE_CACHE_NAMESPACE, id, self.class.tree_cache_version ]) do
      self.class.descendant_ids_for(id)
    end
  end

  # Own + inherited attribute links, de-duplicated by definition and ordered by
  # the link position. Definitions and their options are preloaded to avoid N+1.
  def effective_category_attributes
    ids = [ id ] + ancestor_ids

    CategoryAttribute
      .where(category_id: ids)
      .includes(:category, attribute_definition: :attribute_options)
      .order(:position, :id)
  end

  def effective_attribute_definitions
    effective_category_attributes.map(&:attribute_definition).uniq(&:id)
  end

  def slug_source
    name_en.presence || name_es.presence || name
  end

  # Number of listings attached to the category and all of its descendants.
  def total_listings_count
    return listings_count if new_record?

    Listing.where(category_id: descendant_ids).count
  end

  def deletable?
    listings.none? && children.none?
  end

  # Admin tree rows grouped by parent, with every category preloaded once.
  def self.tree_rows
    categories = order(:position, :id).to_a
    children_by_parent = categories.group_by(&:parent_id)
    rows = []
    walk = lambda do |parent_id, depth|
      (children_by_parent[parent_id] || []).each do |category|
        rows << [ category, depth ]
        walk.call(category.id, depth + 1)
      end
    end
    walk.call(nil, 0)
    rows
  end

  private

  def assign_depth
    self.depth = parent.present? ? parent.depth.to_i + 1 : 0
  end

  def parent_chain_has_no_cycle
    return if parent_id.blank?

    if id.present? && parent_id == id
      errors.add(:parent_id, I18n.t("categories.errors.cycle"))
      return
    end

    visited = Set.new
    node = parent
    while node
      if (id.present? && node.id == id) || !visited.add?(node.id)
        errors.add(:parent_id, I18n.t("categories.errors.cycle"))
        break
      end
      node = node.parent
    end
  end

  def refresh_descendant_depths
    self.class.refresh_depths_from(id)
  end

  def bump_search_cache
    Rails.cache.write(Listing::SEARCH_CACHE_VERSION_KEY, Time.current.to_f)
  end
end
