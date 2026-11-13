# frozen_string_literal: true

module Admin
  class AttributeDefinitionQuery
    include Filterable
    def filters
      {
        q: text_param(:q),
        group: text_param(:group),
        active: boolean_param(:active)
      }
    end

    def groups
      AttributeDefinition.distinct.order(:group).pluck(:group).compact
    end

    def relation
      scope = AttributeDefinition.includes(:attribute_options).order(:group, :position, :id)
      scope = scope.where("attribute_definitions.name::text ILIKE :q OR attribute_definitions.key ILIKE :q",
                          q: "%#{ActiveRecord::Base.sanitize_sql_like(filters[:q])}%") if filters[:q].present?
      scope = scope.where(group: filters[:group]) if filters[:group].present?
      scope = scope.where(active: filters[:active]) unless filters[:active].nil?
      scope
    end

    def sort_options
      {
        "position" => "attribute_definitions.position",
        "key" => "attribute_definitions.key",
        "group" => "attribute_definitions.group",
        "created_at" => "attribute_definitions.created_at"
      }
    end

    def default_sort
      "position"
    end

    protected

    def direction_param
      text_param(:direction, max: 4) == "desc" ? "desc" : "asc"
    end
  end
end
