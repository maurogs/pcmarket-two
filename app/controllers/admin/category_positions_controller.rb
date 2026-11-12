# frozen_string_literal: true

module Admin
  # Reorders siblings and performs explicit parent moves for the category tree.
  # Drag-and-drop reordering is submitted by the shared sortable controller.
  class CategoryPositionsController < AdminOnlyController
    def update
      authorize Category, :reorder?, policy_class: Admin::CategoryPolicy
      category = Category.find(params[:category_id] || Array(params[:ordered_ids]).first)

      Admin::ReorderCategories.new(
        category_id: params[:category_id],
        parent_id: params[:parent_id].presence,
        ordered_ids: Array(params[:ordered_ids]),
        moves: moves_param
      ).call

      audit!(action: "category.reordered", auditable: category,
             changes: { ordered_ids: Array(params[:ordered_ids]), moves: moves_param })
      redirect_to admin_categories_path, notice: t("admin.categories.flash.reordered")
    rescue ActiveRecord::RecordInvalid => error
      redirect_to admin_categories_path,
                  alert: error.record.errors.full_messages.to_sentence
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_categories_path, alert: t("admin.categories.flash.not_found")
    end

    private

    def moves_param
      raw = params[:moves]
      raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : (raw || {}).to_h
    end
  end
end
