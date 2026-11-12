# frozen_string_literal: true

require "test_helper"

class LegalPagesSeedsTest < ActiveSupport::TestCase
  test "seeds every kind idempotently and publishes Spain in all six locales" do
    load Rails.root.join("db/seeds/legal_pages.rb")

    counts = LegalPage.group(:country_code).count
    assert_equal 66, counts["ES"]
    assert_equal 22, counts["FR"]
    assert_equal 11, counts["GB"]
    assert_equal 22, counts["DE"]
    assert_equal 22, counts["IT"]
    assert_equal 22, counts["PT"]

    assert_equal 6, LegalPage.published.where(country_code: "ES").distinct.count(:locale)
    LegalPage::KINDS.each do |kind|
      I18n.available_locales.each do |locale|
        page = LegalPage.find_by(country_code: "ES", locale: locale.to_s, kind: kind, version: "1.0")
        assert page, "missing ES #{kind} in #{locale}"
        assert page.published?
        assert page.review_required?
        assert page.body.to_plain_text.present?
      end
    end

    %w[FR GB DE IT PT].each do |code|
      assert_equal 0, LegalPage.published.where(country_code: code).count
      assert_operator LegalPage.where(country_code: code).count, :>, 0
    end

    assert_no_difference "LegalPage.count" do
      load Rails.root.join("db/seeds/legal_pages.rb")
    end
  end

  test "Spain satisfies the launch checklist after seeding while other countries do not" do
    load Rails.root.join("db/seeds/legal_pages.rb")

    assert countries(:spain).launch_ready?
    assert_not countries(:france).launch_ready?
  end
end
