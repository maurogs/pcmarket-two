# frozen_string_literal: true

module Admin
  class TagPositionsController < AdminOnlyController
    def update
      authorize Tag, :reorder?, policy_class: Admin::TagPolicy

      ids = Array(params[:ordered_ids]).map(&:to_i)
      return redirect_to admin_tags_path, alert: t("admin.tags.flash.nothing_to_reorder") if ids.empty?

      tags = Tag.where(id: ids).index_by(&:id)

      Tag.transaction do
        ids.each_with_index do |id, index|
          tags[id]&.update_columns(position: index + 1, updated_at: Time.current)
        end
      end

      audit!(action: "tags.reordered", auditable: tags.values.first || Tag.first,
             changes: { ordered_ids: ids })
      redirect_to admin_tags_path, notice: t("admin.tags.flash.reordered")
    end
  end
end
