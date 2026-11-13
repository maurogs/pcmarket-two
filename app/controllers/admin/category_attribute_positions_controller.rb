# frozen_string_literal: true

module Admin
  class CategoryAttributePositionsController < AdminOnlyController
    def update
      category = Category.friendly.find(params[:category_id])
      authorize category, :manage_filters?, policy_class: Admin::CategoryPolicy

      ids = Array(params[:ordered_ids]).map(&:to_i)
      rows = category.category_attributes.where(id: ids).index_by(&:id)

      CategoryAttribute.transaction do
        ids.each_with_index do |id, index|
          rows[id]&.update_columns(position: index + 1, updated_at: Time.current)
        end
      end

      Category.where(id: category.id).update_all(updated_at: Time.current)
      audit!(action: "category.filters_reordered", auditable: category,
             changes: { ordered_ids: ids })
      redirect_to admin_category_category_attributes_path(category),
                  notice: t("admin.category_attributes.flash.reordered")
    end
  end
end
