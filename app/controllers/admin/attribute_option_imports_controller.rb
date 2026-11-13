# frozen_string_literal: true

module Admin
  class AttributeOptionImportsController < AdminOnlyController
    def create
      definition = AttributeDefinition.find(params[:attribute_definition_id])
      authorize definition, :manage_options?, policy_class: Admin::AttributeDefinitionPolicy

      result = AttributeOptions::Import.new(definition: definition, text: params[:text]).call
      audit!(action: "attribute_option.imported", auditable: definition,
             changes: { created: result.created, skipped: result.skipped })
      redirect_to edit_admin_attribute_definition_path(definition),
                  notice: t("admin.attribute_definitions.options.flash.imported",
                            created: result.created, skipped: result.skipped)
    end
  end
end
