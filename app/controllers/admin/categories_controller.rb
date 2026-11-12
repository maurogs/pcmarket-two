# frozen_string_literal: true

module Admin
  class CategoriesController < AdminOnlyController
    before_action :set_category, only: %i[edit update destroy]

    def index
      authorize Category, :index?, policy_class: Admin::CategoryPolicy

      @groups = build_groups
      @total = Category.count
    end

    def new
      @category = Category.new(active: true, parent_id: params[:parent_id].presence,
                               position: next_position_for(params[:parent_id]))
      authorize @category, policy_class: Admin::CategoryPolicy
    end

    def create
      @category = Category.new(category_params)
      @category.position = next_position_for(@category.parent_id) if @category.position.zero?
      authorize @category, policy_class: Admin::CategoryPolicy

      if @category.save
        audit!(action: "category.created", auditable: @category, changes: @category.saved_changes)
        redirect_to admin_categories_path, notice: t("admin.categories.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @category, policy_class: Admin::CategoryPolicy
      @own_filters = @category.category_attributes.includes(:attribute_definition).ordered
      @effective_filters = effective_filters
    end

    def update
      authorize @category, policy_class: Admin::CategoryPolicy

      if @category.update(category_params)
        audit!(action: "category.updated", auditable: @category,
               changes: @category.saved_changes.except("updated_at"))
        redirect_to edit_admin_category_path(@category), notice: t("admin.categories.flash.updated")
      else
        @own_filters = @category.category_attributes.includes(:attribute_definition).ordered
        @effective_filters = effective_filters
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @category, policy_class: Admin::CategoryPolicy

      unless @category.deletable?
        redirect_to admin_categories_path,
                    alert: t("admin.categories.flash.not_empty",
                             listings: @category.listings.count,
                             children: @category.children.count)
        return
      end

      @category.destroy!
      audit!(action: "category.destroyed", auditable: @category)
      redirect_to admin_categories_path, notice: t("admin.categories.flash.destroyed")
    end

    private

    def set_category
      @category = Category.friendly.find(params[:id])
    end

    def category_params
      permitted = %i[slug icon parent_id active position]
      translated = I18n.available_locales.flat_map do |locale|
        %i[name description seo_title seo_description].map { |attribute| :"#{attribute}_#{locale}" }
      end

      params.require(:category).permit(*(permitted + translated))
    end

    def next_position_for(parent_id)
      Category.where(parent_id: parent_id.presence).maximum(:position).to_i + 1
    end

    def build_groups
      grouped = Category.order(:position, :id).to_a.group_by(&:parent_id)
      rows = []
      walk = lambda do |parent_id|
        children = grouped[parent_id] || []
        rows << [ parent_id, children ] if children.any?
        children.each { |child| walk.call(child.id) }
      end
      walk.call(nil)
      rows
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
