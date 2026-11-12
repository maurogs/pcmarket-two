# frozen_string_literal: true

require "test_helper"

class LegalPagesTest < ActionDispatch::IntegrationTest
  def create_page(kind: "terms", locale: "es", country: "ES", status: :published,
                  version: "1.0", title: nil, review_required: true)
    page = LegalPage.new(
      country_code: country,
      locale: locale,
      kind: kind,
      version: version,
      status: status,
      title: title || "#{kind} #{locale} #{version}",
      review_required: review_required
    )
    page.body = "<h2>First section</h2><p>First paragraph.</p><h2>Second section</h2><p>Second paragraph.</p>"
    if status.to_sym == :published
      page.published_at = Time.zone.local(2026, 11, 1, 9)
      page.effective_at = page.published_at
    end
    page.save!
    page
  end

  test "renders the document with effective date, version and a generated table of contents" do
    page = create_page(title: "Terms of PCMarket")

    get legal_page_path(kind: "terms")

    assert_response :success
    assert_includes response.body, "Terms of PCMarket"
    assert_includes response.body, I18n.t("legal_pages.public.effective_from")
    assert_includes response.body, I18n.t("legal_pages.public.version", version: "1.0")
    assert_includes response.body, "First section"
    assert_includes response.body, "Second section"
    assert_includes response.body, "#section-1"
  end

  test "selects the country from the launched-country cookie" do
    create_page(title: "Spanish terms", locale: "es", country: "ES")
    create_page(title: "French terms", locale: "fr", country: "FR")
    cookies[:country] = "FR"

    with_stub(Country, :launched_codes, %w[ES FR]) do
      get legal_page_path(kind: "terms")
    end

    assert_response :success
    assert_includes response.body, "French terms"
    assert_not_includes response.body, "Spanish terms"
  end

  test "falls back to the country default locale when the requested locale is missing" do
    create_page(title: "Condiciones en español", locale: "es", country: "ES")

    get "/en/legal/terms"

    assert_response :success
    assert_includes response.body, "Condiciones en español"
  end

  test "returns 404 when there is no published page" do
    create_page(status: :draft)

    get legal_page_path(kind: "terms")

    assert_response :not_found
  end

  test "lists previous versions and marks the current one" do
    create_page(version: "1.0", title: "Terms v1")
    create_page(version: "0.9", title: "Terms v0.9")

    get legal_page_versions_path(kind: "terms")

    assert_response :success
    assert_includes response.body, I18n.t("legal_pages.public.version", version: "1.0")
    assert_includes response.body, I18n.t("legal_pages.public.version", version: "0.9")
    assert_includes response.body, I18n.t("legal_pages.versions.current")
  end

  test "never renders the lawyer review note publicly" do
    create_page(review_required: true)

    get legal_page_path(kind: "terms")

    assert_response :success
    assert_not_includes response.body, I18n.t("admin.legal_pages.show.review_required")
    assert_not_includes response.body, "Template — must be reviewed"
  end

  test "serves the legal index for the visitor country" do
    create_page(title: "Terms of PCMarket")
    create_page(kind: "privacy", title: "Privacy of PCMarket")

    get legal_pages_path

    assert_response :success
    assert_includes response.body, I18n.t("legal_pages.public.index_title")
    assert_includes response.body, "Terms of PCMarket"
    assert_includes response.body, "Privacy of PCMarket"
  end

  test "the public legal page is translated" do
    create_page(title: "Conditions")

    get "/en/legal/terms"

    assert_response :success
    assert_includes response.body, I18n.t("legal_pages.public.effective_from", locale: :en)
  end
end
