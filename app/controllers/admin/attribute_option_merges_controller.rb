# frozen_string_literal: true

module Admin
  class AttributeOptionMergesController < AdminOnlyController
    def create
      definition = AttributeDefinition.find(params[:attribute_definition_id])
      option = definition.attribute_options.find(params[:option_id])
      target = definition.attribute_options.find(params[:target_id])
      authorize option, :merge?, policy_class: Admin::AttributeOptionPolicy

      updated = AttributeOptions::Merge.new(option: option, target: target).call
      audit!(action: "attribute_option.merged", auditable: target,
             changes: { merged_option_id: option.id, merged_value: option.value,
                        affected_listings: updated })
      redirect_to edit_admin_attribute_definition_path(definition),
                  notice: t("admin.attribute_definitions.options.flash.merged",
                            count: updated, target: target.value)
    rescue ArgumentError
      redirect_to edit_admin_attribute_definition_path(definition),
                  alert: t("admin.attribute_definitions.options.flash.merge_invalid")
    end
  end
end
