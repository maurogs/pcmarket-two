# frozen_string_literal: true

module Admin
  class CategoryAttributesController < AdminOnlyController
    before_action :set_category
    before_action :set_row, only: %i[update destroy]

    def index
      authorize @category, :manage_filters?, policy_class: Admin::CategoryPolicy

      @own_filters = @category.category_attributes.includes(:attribute_definition).ordered
      @effective_filters = effective_filters
      @available_definitions = AttributeDefinition.active.ordered
    end

    def create
      authorize @category, :manage_filters?, policy_class: Admin::CategoryPolicy

      definition = AttributeDefinition.find(params[:attribute_definition_id])
      row = @category.category_attributes.find_or_initialize_by(attribute_definition: definition)
      if row.persisted?
        redirect_to admin_category_category_attributes_path(@category),
                    alert: t("admin.category_attributes.flash.duplicate")
        return
      end

      row.position = (@category.category_attributes.maximum(:position) || 0) + 1
      if row.save
        audit!(action: "category.filter_added", auditable: @category,
               changes: { attribute_definition_id: definition.id })
        redirect_to admin_category_category_attributes_path(@category),
                    notice: t("admin.category_attributes.flash.added")
      else
        redirect_to admin_category_category_attributes_path(@category),
                    alert: row.errors.full_messages.to_sentence
      end
    end

    def update
      authorize @category, :manage_filters?, policy_class: Admin::CategoryPolicy

      if @row.update(category_attribute_params)
        audit!(action: "category.filter_updated", auditable: @category,
               changes: @row.saved_changes.except("updated_at"))
        redirect_to admin_category_category_attributes_path(@category),
                    notice: t("admin.category_attributes.flash.updated")
      else
        redirect_to admin_category_category_attributes_path(@category),
                    alert: @row.errors.full_messages.to_sentence
      end
    end

    def destroy
      authorize @category, :manage_filters?, policy_class: Admin::CategoryPolicy

      unless @row.category_id == @category.id
        redirect_to admin_category_category_attributes_path(@category),
                    alert: t("admin.category_attributes.flash.inherited")
        return
      end

      @row.destroy!
      audit!(action: "category.filter_removed", auditable: @category,
             changes: { attribute_definition_id: @row.attribute_definition_id })
      redirect_to admin_category_category_attributes_path(@category),
                  notice: t("admin.category_attributes.flash.removed")
    end

    private

    def set_category
      @category = Category.friendly.find(params[:category_id])
    end

    def set_row
      @row = CategoryAttribute.find(params[:id])
      return if @row.category_id == @category.id

      redirect_to admin_category_category_attributes_path(@category),
                  alert: t("admin.category_attributes.flash.inherited")
    end

    def category_attribute_params
      params.require(:category_attribute).permit(:required, :position)
    end

    def effective_filters
      rows = @category.effective_category_attributes.to_a
      own_definition_ids = rows.select { |row| row.category_id == @category.id }
                               .map(&:attribute_definition_id)
      rows.reject do |row|
        row.category_id != @category.id && own_definition_ids.include?(row.attribute_definition_id)
      end
    end
  end
end
