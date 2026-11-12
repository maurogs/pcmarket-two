# frozen_string_literal: true

module Api
  module V1
    class AttributeDefinitionSerializer < BaseSerializer
      attributes :id, :key, :name, :group, :input_type, :unit,
                 :filterable, :show_on_card, :position, :active

      many :attribute_options, resource: AttributeOptionSerializer

      attribute :required_flag do |definition|
        params[:required_flags].present? && params[:required_flags].key?(definition.id)
      end
    end
  end
end
