# frozen_string_literal: true

module Admin
  class AttributeOptionPositionsController < AdminOnlyController
    def update
      definition = AttributeDefinition.find(params[:attribute_definition_id])
      authorize definition, :manage_options?, policy_class: Admin::AttributeDefinitionPolicy

      ids = Array(params[:ordered_ids]).map(&:to_i)
      options = definition.attribute_options.where(id: ids).index_by(&:id)

      AttributeOption.transaction do
        ids.each_with_index do |id, index|
          options[id]&.update_columns(position: index + 1, updated_at: Time.current)
        end
      end

      audit!(action: "attribute_options.reordered", auditable: definition,
             changes: { ordered_ids: ids })
      redirect_to edit_admin_attribute_definition_path(definition),
                  notice: t("admin.attribute_definitions.options.flash.reordered")
    end
  end
end
