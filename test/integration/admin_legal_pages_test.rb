# frozen_string_literal: true

require "test_helper"

class AdminLegalPagesTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    sign_in users(:admin)
  end

  test "creates a rich-text draft and renders a preview" do
    post admin_legal_pages_path(locale: :en), params: {
      legal_page: {
        country_code: "ES", locale: "es", kind: "terms", title: "Términos",
        version: "1", body: "<p>Estos son los términos.</p>"
      }
    }

    page = LegalPage.find_by!(country_code: "ES", locale: "es", kind: "terms", version: "1")
    assert_redirected_to admin_legal_page_path(page, locale: :en)
    assert_equal "Estos son los términos.", page.plain_body.strip
    assert_equal "legal_page.created", AdminAuditLog.last.action

    get admin_legal_page_path(page, locale: :en)
    assert_response :success
    assert_includes response.body, "Estos son los términos."
  end

  test "edits draft content but not published versions" do
    page = create_page(body: "Old body")

    patch admin_legal_page_path(page, locale: :en), params: {
      legal_page: { title: "Updated title", body: "<p>New body</p>" }
    }

    assert_redirected_to admin_legal_page_path(page, locale: :en)
    page.reload
    assert_equal "Updated title", page.title
    assert_equal "New body", page.plain_body.strip
  end

  test "creates a new draft version from the latest content" do
    page = create_page(version: "1", body: "First version")

    assert_difference "LegalPage.count", 1 do
      post admin_legal_page_version_path(page, locale: :en)
    end

    copy = LegalPage.order(:id).last
    assert_equal "2", copy.version
    assert_predicate copy, :draft?
    assert_equal "First version", copy.plain_body.strip
    assert_redirected_to edit_admin_legal_page_path(copy, locale: :en)
  end

  test "published versions are read-only and publication records the effective date" do
    page = create_page
    newer = create_page(version: "2", title: "Newer terms", body: "Newer body")

    post admin_legal_page_publication_path(page, locale: :en),
         params: { effective_at: Date.current.to_s }

    assert_redirected_to admin_legal_page_path(page, locale: :en)
    assert_predicate page.reload, :published?
    assert_equal Date.current, page.effective_at.to_date
    assert_equal "1", LegalPage.current(country: countries(:spain), locale: :es, kind: :terms).version

    post admin_legal_page_publication_path(newer, locale: :en),
         params: { effective_at: Date.current.to_s }
    assert_equal "2", LegalPage.current(country: countries(:spain), locale: :es, kind: :terms).version

    get edit_admin_legal_page_path(page, locale: :en)
    assert_redirected_to admin_legal_page_path(page, locale: :en)
    assert_equal I18n.t("admin.legal_pages.flash.published_read_only", locale: :en), flash[:alert]
  end

  test "current uses the requested locale, then the country default, then Spanish" do
    france = countries(:france)
    create_page(country: france, locale: "fr", version: "1", title: "Conditions FR",
                body: "FR body").publish!(effective_at: Date.current)
    create_page(country: france, locale: "es", version: "1", title: "Términos ES",
                body: "ES body").publish!(effective_at: Date.current)

    french = LegalPage.current(country: france, locale: :de, kind: :terms)
    assert_equal "fr", french.locale

    create_page(country: france, locale: "en", version: "1", title: "English terms",
                body: "EN body").publish!(effective_at: Date.current)
    english = LegalPage.current(country: france, locale: :en, kind: :terms)
    assert_equal "en", english.locale

    portugal = countries(:portugal)
    create_page(country: portugal, locale: "es", version: "1", title: "Términos PT",
                body: "PT body").publish!(effective_at: Date.current)
    spanish = LegalPage.current(country: portugal, locale: :de, kind: :terms)
    assert_equal "es", spanish.locale
  end

  test "compares two versions line by line" do
    page = create_page(version: "1", body: "Line one\nLine two")
    newer = create_page(version: "2", body: "Line one\nLine three")

    get admin_legal_page_comparison_path(newer, locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("admin.legal_pages.comparison.kinds.removed", locale: :en)
    assert_includes response.body, I18n.t("admin.legal_pages.comparison.kinds.added", locale: :en)
    assert_includes response.body, "Line three"
    assert_includes response.body, page.version
  end

  test "notifying queues one translated email per active user in the country" do
    page = create_page(country: countries(:france), locale: "fr", kind: "privacy")
    page.publish!(effective_at: Date.current)

    active = create_user(email: "fr-active@example.com", username: "fr_active",
                         country_code: "FR", locale: "fr")
    create_user(email: "fr-deleted@example.com", username: "fr_deleted",
                country_code: "FR", locale: "fr", deleted_at: Time.current)

    assert_enqueued_emails 1 do
      perform_enqueued_jobs(only: LegalPages::NotifyJob) do
        post admin_legal_page_notification_path(page, locale: :en)
      end
    end

    assert_redirected_to admin_legal_page_path(page, locale: :en)
    assert_not_nil page.reload.notified_at
    assert_equal "legal_page.notified", AdminAuditLog.last.action
    assert_equal "fr", active.locale
  end

  test "only terms and privacy can notify users" do
    page = create_page(kind: "cookies")
    page.publish!(effective_at: Date.current)

    assert_no_enqueued_emails do
      post admin_legal_page_notification_path(page, locale: :en)
    end

    assert_equal I18n.t("admin.legal_pages.flash.not_notifiable", locale: :en), flash[:alert]
  end

  private

  def create_page(country: countries(:spain), locale: "es", kind: "terms", version: "1",
                  title: "Legal page", body: "Body")
    page = LegalPage.create!(country_code: country.code, locale: locale, kind: kind,
                             title: title, version: version, status: :draft)
    page.body = body
    page.save!
    page
  end

  def create_user(email:, username:, country_code:, locale:, deleted_at: nil)
    User.create!(
      email: email, username: username, password: "Password123!",
      password_confirmation: "Password123!", first_name: "Legal", last_name: "User",
      country_code: country_code, locale: locale, confirmed_at: Time.current,
      terms_accepted: "1", terms_accepted_at: Time.current, deleted_at: deleted_at
    )
  end
end
