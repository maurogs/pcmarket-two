# frozen_string_literal: true

module Api
  module V1
    class CategorySerializer < BaseSerializer
      attributes :id, :slug, :name, :description, :icon, :position,
                 :depth, :listings_count, :active

      attribute :children do |category|
        next [] unless category.children.loaded?

        category.children.select(&:active?)
                .sort_by { |child| [ child.position.to_i, child.id ] }
                .map { |child| CategorySerializer.new(child).serializable_hash }
      end
    end
  end
end
