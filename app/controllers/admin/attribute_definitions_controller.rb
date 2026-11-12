# frozen_string_literal: true

module Admin
  class AttributeDefinitionsController < AdminOnlyController
    before_action :set_definition, only: %i[edit update destroy]

    def index
      authorize AttributeDefinition, :index?, policy_class: Admin::AttributeDefinitionPolicy

      @query = Admin::AttributeDefinitionQuery.new(params: params)
    end

    def new
      @definition = AttributeDefinition.new(active: true, filterable: true, position: next_position)
      authorize @definition, policy_class: Admin::AttributeDefinitionPolicy
    end

    def create
      @definition = AttributeDefinition.new(definition_params)
      authorize @definition, policy_class: Admin::AttributeDefinitionPolicy

      if @definition.save
        audit!(action: "attribute_definition.created", auditable: @definition,
               changes: @definition.saved_changes)
        redirect_to edit_admin_attribute_definition_path(@definition),
                    notice: t("admin.attribute_definitions.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @definition, policy_class: Admin::AttributeDefinitionPolicy

      @options = @definition.attribute_options.ordered.to_a
      @usage = Admin::AttributeUsage.for(@definition)
      @new_option = @definition.attribute_options.new(active: true, popular: false)
    end

    def update
      authorize @definition, policy_class: Admin::AttributeDefinitionPolicy

      if @definition.update(definition_params)
        audit!(action: "attribute_definition.updated", auditable: @definition,
               changes: @definition.saved_changes.except("updated_at"))
        redirect_to edit_admin_attribute_definition_path(@definition),
                    notice: t("admin.attribute_definitions.flash.updated")
      else
        prepare_edit
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @definition, policy_class: Admin::AttributeDefinitionPolicy

      if @definition.used?
        redirect_to edit_admin_attribute_definition_path(@definition),
                    alert: t("admin.attribute_definitions.flash.in_use")
        return
      end

      @definition.destroy!
      audit!(action: "attribute_definition.destroyed", auditable: @definition)
      redirect_to admin_attribute_definitions_path,
                  notice: t("admin.attribute_definitions.flash.destroyed")
    end

    private

    def set_definition
      @definition = AttributeDefinition.find(params[:id])
    end

    def definition_params
      permitted = %i[group input_type unit filterable show_on_card position active]
      permitted << :key if action_name == "create"
      params.require(:attribute_definition).permit(
        *(permitted + translated_name_params)
      )
    end

    def translated_name_params
      I18n.available_locales.map { |locale| :"name_#{locale}" }
    end

    def next_position
      (AttributeDefinition.maximum(:position) || 0) + 1
    end

    def prepare_edit
      @options = @definition.attribute_options.ordered.to_a
      @usage = Admin::AttributeUsage.for(@definition)
      @new_option = @definition.attribute_options.new(active: true, popular: false)
    end
  end
end
