# frozen_string_literal: true

module Admin
  class FeaturesController < AdminOnlyController
    def index
      authorize :features, :index?, policy_class: Admin::FeaturePolicy

      @features = Flipper.features.map(&:name).sort.map { |name| feature_row(name) }
    end

    def update
      authorize :features, :update?, policy_class: Admin::FeaturePolicy

      name = params[:id].to_s.to_sym
      unless Flipper.features.map(&:name).include?(name)
        raise ActiveRecord::RecordNotFound
      end

      apply_enabled(name) if params.key?(:enabled)
      apply_percentage(name) if params.key?(:percentage)

      flag = FeatureFlag.for(name).tap(&:save!)
      audit!(action: "feature_flag.updated", auditable: flag,
             changes: { enabled: Flipper.enabled?(name),
                        percentage_of_actors: percentage_for(name) })
      redirect_to admin_features_path, notice: t("admin.features.flash.updated", name: name)
    end

    private

    def feature_row(name)
      {
        name: name,
        enabled: Flipper.enabled?(name),
        percentage: percentage_for(name),
        description: description_for(name)
      }
    end

    def percentage_for(name)
      Flipper.feature(name).percentage_of_actors_value.to_i
    rescue StandardError
      0
    end

    def description_for(name)
      key = FeatureFlag.find_by(key: name.to_s)&.description_key.presence ||
            "admin.features.descriptions.#{name}"
      t(key, default: t("admin.features.no_description"))
    end

    def apply_enabled(name)
      if ActiveModel::Type::Boolean.new.cast(params[:enabled])
        Flipper.enable(name)
      else
        Flipper.disable(name)
      end
    end

    def apply_percentage(name)
      percentage = params[:percentage].to_i.clamp(0, 100)
      if percentage.positive?
        Flipper.enable_percentage_of_actors(name, percentage)
      else
        Flipper.disable_percentage_of_actors(name)
      end
    end
  end
end
