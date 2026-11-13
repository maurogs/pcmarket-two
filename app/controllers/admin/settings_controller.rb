# frozen_string_literal: true

module Admin
  class SettingsController < AdminOnlyController
    def show
      authorize Setting, :index?, policy_class: Admin::SettingPolicy

      load_settings
    end

    def update
      authorize Setting, :update?, policy_class: Admin::SettingPolicy

      result = Settings::Update.new(params: settings_params).call
      if result.success?
        if result.changes.any?
          setting = Setting.find_by(key: result.changes.keys.first)
          audit!(action: "setting.updated", auditable: setting, changes: result.changes)
        end
        redirect_to admin_settings_path, notice: t("admin.settings.flash.updated")
      else
        load_settings
        @errors = result.errors
        render :show, status: :unprocessable_entity
      end
    end

    private

    def load_settings
      @settings = Setting.order(:group, :key).to_a
      @groups = @settings.group_by(&:group)
    end

    def settings_params
      params.require(:settings).permit(*Setting.pluck(:key).map(&:to_sym)).to_h
    end
  end
end
