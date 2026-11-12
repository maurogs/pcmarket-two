# frozen_string_literal: true

require "test_helper"

class AdminSettingsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
    load Rails.root.join("db/seeds/settings.rb")
    Rails.cache.clear
    Flipper.add(:offers)
    Flipper.disable(:offers)
    Flipper.disable_percentage_of_actors(:offers)
  end

  teardown do
    Setting.set(:maintenance_mode, false)
    Flipper.disable(:offers)
    Flipper.disable_percentage_of_actors(:offers)
    Rails.cache.clear
  end

  test "renders every setting grouped by its section" do
    get admin_settings_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("admin.settings.groups.general", locale: :en)
    assert_includes response.body, I18n.t("admin.settings.groups.maintenance", locale: :en)
    assert_includes response.body, I18n.t("admin.settings.keys.commission_percent", locale: :en)
    assert_select "input[name='settings[commission_percent]']", 1
    assert_select "input[type='checkbox'][name='settings[maintenance_mode]']", 1
  end

  test "validates commission_percent between 0 and 50" do
    patch admin_settings_path(locale: :en), params: { settings: { commission_percent: "75" } }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("settings.errors.commission_percent", locale: :en)
    assert_equal 0, Setting.get(:commission_percent).to_i

    patch admin_settings_path(locale: :en), params: { settings: { commission_percent: "25" } }

    assert_redirected_to admin_settings_path(locale: :en)
    assert_equal BigDecimal("25"), Setting.get(:commission_percent).to_d
    assert_equal "setting.updated", AdminAuditLog.last.action
  end

  test "rejects values that do not match the declared type" do
    patch admin_settings_path(locale: :en), params: { settings: { max_images_per_listing: "many" } }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("settings.errors.invalid_type", locale: :en)
    assert_equal 12, Setting.get(:max_images_per_listing)
  end

  test "maintenance mode returns a translated 503 to visitors but lets staff browse" do
    Setting.set(:maintenance_mode, true)
    sign_out users(:admin)

    get root_path(locale: :en)
    assert_response :service_unavailable
    assert_equal "3600", response.headers["Retry-After"]
    assert_includes response.body, I18n.t("maintenance.title", locale: :en)

    get "/up"
    assert_response :success

    post stripe_webhook_path
    assert_response :bad_request

    sign_in users(:admin)
    get root_path(locale: :en)
    assert_response :success
  end

  test "feature flags can be toggled and rolled out by percentage" do
    get admin_features_path(locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("admin.features.descriptions.offers", locale: :en)

    patch admin_feature_path("offers", locale: :en), params: { enabled: "1", percentage: "40" }

    assert_redirected_to admin_features_path(locale: :en)
    assert Flipper.enabled?(:offers)
    assert_equal 40, Flipper.feature(:offers).percentage_of_actors_value
    assert_equal "feature_flag.updated", AdminAuditLog.last.action

    patch admin_feature_path("offers", locale: :en), params: { enabled: "0", percentage: "0" }

    refute Flipper.enabled?(:offers)
    assert_equal 0, Flipper.feature(:offers).percentage_of_actors_value
  end
end
