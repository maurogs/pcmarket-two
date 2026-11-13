# frozen_string_literal: true

require "test_helper"

class AdminCountriesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
    Rails.cache.clear
  end

  test "the launch checklist blocks activation without legal pages and regions" do
    country = countries(:portugal)

    get edit_admin_country_path(country, locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("admin.countries.checklist.pending", locale: :en)
    assert_includes response.body, I18n.t("admin.countries.checklist.items.regions.title", locale: :en)

    patch admin_country_path(country, locale: :en), params: { country: { active: "1" } }

    assert_response :unprocessable_entity
    refute_predicate country.reload, :active?
    assert_includes response.body, I18n.t("countries.errors.missing_regions", locale: :en)
  end

  test "activates a country once every legal page and a region exist" do
    country = countries(:france)
    country.regions.create!(code: "FR-IDF", name: "Île-de-France", position: 1)
    publish_all_legal_pages(country)

    patch admin_country_path(country, locale: :en), params: {
      country: { active: "1", vat_rate: "20", default_locale: "fr" }
    }

    assert_redirected_to admin_countries_path(locale: :en)
    assert_predicate country.reload, :active?
    assert_includes Country.launched_codes, "FR"
  end

  test "deactivating a country hides its listings and blocks new ones" do
    spain = countries(:spain)
    listing = listings(:published_gpu)
    assert_includes Listing.visible, listing

    spain.update!(active: false)
    assert_not_includes Listing.visible, listing

    error = assert_raises(ActiveRecord::RecordInvalid) do
      create_listing!(store: stores(:confirmed_store), seller: users(:confirmed),
                      title: "Blocked Spanish listing", country_code: "ES")
    end

    assert_includes error.record.errors[:country_code],
                    I18n.t("listings.errors.country_not_launched")
  end

  test "region import creates and updates codes idempotently" do
    country = countries(:france)
    text = "FR-IDF,Île-de-France\nFR-BRE,Bretagne"

    assert_difference "Region.where(country_code: 'FR').count", 2 do
      post admin_country_region_import_path(country, locale: :en), params: { text: text }
    end

    assert_redirected_to admin_country_regions_path(country, locale: :en)
    assert_equal "Bretagne", country.regions.find_by!(code: "FR-BRE").name

    assert_no_difference "Region.count" do
      post admin_country_region_import_path(country, locale: :en), params: {
        text: "FR-IDF,Île-de-France\nFR-BRE,Brittany"
      }
    end
    assert_equal "Brittany", country.regions.find_by!(code: "FR-BRE").name
  end

  test "regions can be created, updated and deleted" do
    country = countries(:france)

    post admin_country_regions_path(country, locale: :en), params: {
      region: { code: "FR-OCC", name: "Occitanie", position: 5 }
    }
    region = country.regions.find_by!(code: "FR-OCC")
    assert_redirected_to admin_country_regions_path(country, locale: :en)

    patch admin_country_region_path(country, region, locale: :en), params: {
      region: { name: "Occitanie Sud" }
    }
    assert_equal "Occitanie Sud", region.reload.name

    assert_difference "Region.count", -1 do
      delete admin_country_region_path(country, region, locale: :en)
    end
  end

  private

  def publish_all_legal_pages(country)
    LegalPage::KINDS.each do |kind|
      LegalPage.create!(
        country_code: country.code, locale: country.default_locale, kind: kind,
        title: "FR #{kind}", version: "1", status: :published,
        published_at: 2.days.ago, effective_at: 1.day.ago
      )
    end
  end
end
