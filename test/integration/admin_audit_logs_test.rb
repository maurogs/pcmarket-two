# frozen_string_literal: true

require "test_helper"

class AdminAuditLogsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "moderators cannot read the audit log" do
    sign_out users(:admin)
    sign_in users(:moderator)

    get admin_audit_logs_path(locale: :en)

    assert_response :redirect
  end

  test "admin mutations write audit entries with actor and request details" do
    listing = listings(:amd_gpu)

    patch admin_listing_path(listing, locale: :en),
          params: { listing: { title: "Updated AMD listing title" } }

    log = AdminAuditLog.last
    assert_equal "listing.updated", log.action
    assert_equal users(:admin), log.actor
    assert_equal listing, log.auditable
    assert log.changes.key?("title")
    assert log.ip.present?
  end

  test "the index shows and filters audit entries by actor, type and date" do
    AdminAuditLog.record!(actor: users(:admin), action: "listing.approved",
                          auditable: listings(:published_gpu))
    AdminAuditLog.record!(actor: users(:moderator), action: "store.verified",
                          auditable: stores(:confirmed_store))

    get admin_audit_logs_path(locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("admin.audit_logs.actions.listing.approved", locale: :en)

    get admin_audit_logs_path(locale: :en, actor_id: users(:moderator).id)
    assert_response :success
    assert_select "tbody", text: /#{I18n.t("admin.audit_logs.actions.store.verified", locale: :en)}/
    assert_select "tbody", text: /#{I18n.t("admin.audit_logs.actions.listing.approved", locale: :en)}/, count: 0

    get admin_audit_logs_path(locale: :en, auditable_type: "Listing")
    assert_response :success
    assert_select "tbody", text: /#{I18n.t("admin.audit_logs.actions.listing.approved", locale: :en)}/
    assert_select "tbody", text: /#{I18n.t("admin.audit_logs.actions.store.verified", locale: :en)}/, count: 0

    get admin_audit_logs_path(locale: :en, date_from: 2.days.ago.to_date, date_to: Date.current)
    assert_response :success
  end
end
