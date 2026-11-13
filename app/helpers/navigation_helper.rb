# frozen_string_literal: true

module NavigationHelper
  # One query for the whole active tree, memoised for the request. The rendered
  # navigation itself is fragment-cached per locale in the view.
  def navigation_tree
    @navigation_tree ||= begin
      categories = Category.active.order(:position, :id).to_a
      children_by_parent = categories.group_by(&:parent_id)
      categories.filter_map do |category|
        next unless category.parent_id.nil?

        [ category, children_by_parent[category.id] || [] ]
      end
    end
  end

  def all_category_label(category)
    t("nav.categories.all_category", category: category.name)
  end
end
