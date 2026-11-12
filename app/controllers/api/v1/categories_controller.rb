# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < BaseController
      def index
        data = Catalogue.new.categories_tree
        etag = [ "api/v1/categories", I18n.locale, Category.tree_cache_version ]
        cache_public_catalogue!
        return if conditional_get!(etag: etag, public: current_user.nil?)

        render_data(data)
      end

      def show
        category = Category.active.friendly.find(params[:id])
        cache_public_catalogue!
        return if conditional_get!(etag: [ category, I18n.locale ],
                                   last_modified: category.updated_at,
                                   public: current_user.nil?)

        definitions = category.effective_attribute_definitions
        required_ids = category.effective_category_attributes.select(&:required?)
                                  .map(&:attribute_definition_id)

        render_data({
          category: CategorySerializer.new(category).serializable_hash,
          filters: definitions.select(&:filterable?).map do |definition|
            AttributeDefinitionSerializer.new(
              definition, params: { required_flags: required_ids.index_with(true) }
            ).serializable_hash
          end,
          required_attribute_definition_ids: required_ids
        })
      end
    end
  end
end
