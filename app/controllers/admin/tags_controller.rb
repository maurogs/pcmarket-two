# frozen_string_literal: true

module Admin
  class TagsController < AdminOnlyController
    before_action :set_tag, only: %i[edit update destroy]

    def index
      authorize Tag, :index?, policy_class: Admin::TagPolicy

      scope = Tag.all
      scope = scope.where(kind: params[:kind]) if Tag.kinds.key?(params[:kind].to_s)
      scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?
      if params[:q].present?
        scope = scope.where("tags.name::text ILIKE ?",
                            "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%")
      end

      @tags = scope.left_joins(:listing_tags)
                  .select("tags.*, COUNT(listing_tags.id) AS usage_count")
                  .group("tags.id")
                  .order(:kind, :position, :id)
    end

    def new
      @tag = Tag.new(active: true, kind: params[:kind].presence || "product_label",
                     position: next_position)
      authorize @tag, policy_class: Admin::TagPolicy
    end

    def create
      @tag = Tag.new(tag_params)
      @tag.position = next_position if @tag.position.zero?
      authorize @tag, policy_class: Admin::TagPolicy

      if @tag.save
        audit!(action: "tag.created", auditable: @tag, changes: @tag.saved_changes)
        redirect_to admin_tags_path, notice: t("admin.tags.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @tag, policy_class: Admin::TagPolicy
    end

    def update
      authorize @tag, policy_class: Admin::TagPolicy

      if @tag.update(tag_params)
        audit!(action: "tag.updated", auditable: @tag,
               changes: @tag.saved_changes.except("updated_at"))
        redirect_to admin_tags_path, notice: t("admin.tags.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @tag, policy_class: Admin::TagPolicy

      if @tag.listings.exists?
        redirect_to admin_tags_path, alert: t("admin.tags.flash.in_use")
        return
      end

      @tag.destroy!
      audit!(action: "tag.destroyed", auditable: @tag)
      redirect_to admin_tags_path, notice: t("admin.tags.flash.destroyed")
    end

    private

    def set_tag
      @tag = Tag.friendly.find(params[:id])
    end

    def tag_params
      permitted = %i[colour position active]
      permitted << :kind if action_name == "create"
      params.require(:tag).permit(*(permitted + I18n.available_locales.map { |locale| :"name_#{locale}" }))
    end

    def next_position
      (Tag.maximum(:position) || 0) + 1
    end
  end
end
