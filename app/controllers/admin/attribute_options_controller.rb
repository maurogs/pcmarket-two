# frozen_string_literal: true

module Admin
  class AttributeOptionsController < AdminOnlyController
    before_action :set_definition
    before_action :set_option, only: %i[update destroy]

    def create
      @option = @definition.attribute_options.new(option_params)
      authorize @option, :create?, policy_class: Admin::AttributeOptionPolicy
      @option.position = (@definition.attribute_options.maximum(:position) || 0) + 1

      if @option.save
        audit!(action: "attribute_option.created", auditable: @option,
               changes: @option.saved_changes)
        redirect_to edit_admin_attribute_definition_path(@definition),
                    notice: t("admin.attribute_definitions.options.flash.created")
      else
        redirect_to edit_admin_attribute_definition_path(@definition),
                    alert: @option.errors.full_messages.to_sentence
      end
    end

    def update
      authorize @option, :update?, policy_class: Admin::AttributeOptionPolicy

      if @option.update(option_params)
        audit!(action: "attribute_option.updated", auditable: @option,
               changes: @option.saved_changes.except("updated_at"))
        redirect_to edit_admin_attribute_definition_path(@definition),
                    notice: t("admin.attribute_definitions.options.flash.updated")
      else
        redirect_to edit_admin_attribute_definition_path(@definition),
                    alert: @option.errors.full_messages.to_sentence
      end
    end

    def destroy
      authorize @option, :destroy?, policy_class: Admin::AttributeOptionPolicy

      if @option.used?
        redirect_to edit_admin_attribute_definition_path(@definition),
                    alert: t("admin.attribute_definitions.options.flash.in_use")
        return
      end

      @option.destroy!
      audit!(action: "attribute_option.destroyed", auditable: @option)
      redirect_to edit_admin_attribute_definition_path(@definition),
                  notice: t("admin.attribute_definitions.options.flash.destroyed")
    end

    private

    def set_definition
      @definition = AttributeDefinition.find(params[:attribute_definition_id])
    end

    def set_option
      @option = @definition.attribute_options.find(params[:id])
    end

    def option_params
      params.require(:attribute_option).permit(
        :value, :position, :popular, :active,
        *I18n.available_locales.map { |locale| :"label_#{locale}" }
      )
    end
  end
end
