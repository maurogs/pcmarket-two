# frozen_string_literal: true

module Admin
  # Reorders siblings or moves a category to another parent. Position updates
  # use update_columns inside one transaction and then touch the affected rows so
  # the navigation/descendant caches are invalidated.
  class ReorderCategories
    def initialize(category_id: nil, parent_id: nil, ordered_ids: [], moves: {})
      @category_id = category_id
      @parent_id = parent_id
      @ordered_ids = Array(ordered_ids).map(&:to_i).uniq
      @moves = moves.respond_to?(:to_h) ? moves.to_h : {}
    end

    def call
      Category.transaction do
        move_categories!
        reorder_siblings! if @ordered_ids.any?
      end

      @ordered_ids.any? || @moves.any?
    end

    private

    def move_categories!
      @moves.each do |category_id, target_parent_id|
        category = Category.find_by(id: category_id)
        next if category.blank?
        next if target_parent_id.to_s == "keep"

        new_parent_id = target_parent_id.to_s == "root" ? nil : target_parent_id.presence&.to_i
        next if category.parent_id == new_parent_id

        category.update!(parent_id: new_parent_id)
        next_position = Category.where(parent_id: new_parent_id).maximum(:position).to_i + 1
        category.update_columns(position: next_position, updated_at: Time.current)
      end
    end

    def reorder_siblings!
      sibling_ids = Category.where(parent_id: @parent_id, id: @ordered_ids)
                            .order(:position, :id).pluck(:id)
      ordered = (@ordered_ids & sibling_ids) + (sibling_ids - @ordered_ids)

      ordered.each_with_index do |id, index|
        Category.where(id: id).update_all(position: index + 1, updated_at: Time.current)
      end
    end
  end
end
