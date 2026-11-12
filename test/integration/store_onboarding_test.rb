# frozen_string_literal: true

require "test_helper"

class StoreOnboardingTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "listing an item without a store redirects to store onboarding" do
    get new_sell_listing_path(locale: :en)

    assert_redirected_to new_store_path(locale: :en)
    assert_equal I18n.t("sell.errors.store_required", locale: :en), flash[:alert]
  end

  test "store settings without a store redirect to onboarding" do
    get edit_store_path(locale: :en)

    assert_redirected_to new_store_path(locale: :en)
  end

  test "the store onboarding form renders" do
    get new_store_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("stores.new.title", locale: :en)
    assert_includes response.body, I18n.t("stores.form.business_intro", locale: :en)
    assert_includes response.body, 'name="store[kind]"'
  end

  test "a business store with an invalid Spanish tax id is rejected" do
    assert_no_difference "Store.count" do
      post store_path(locale: :en), params: {
        store: business_params(tax_id: "B12345678")
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("errors.messages.invalid_spanish_tax_id", locale: :en)
  end

  test "a valid business store is created and leads back to the listing wizard" do
    assert_difference "Store.count", 1 do
      post store_path(locale: :en), params: {
        store: business_params(tax_id: "B12345674")
      }
    end

    assert_redirected_to new_sell_listing_path(locale: :en)
    store = Store.find_by!(user: users(:admin))
    assert store.business?
    assert_equal regions(:madrid), store.region
    assert_equal "Madrid", store.province
    assert_equal "28001", store.postal_code
  end

  test "an individual store does not need the business fields" do
    assert_difference "Store.count", 1 do
      post store_path(locale: :en), params: {
        store: {
          kind: "individual",
          name: "Admin's Spare Parts",
          region_id: regions(:madrid).id,
          city: "Madrid",
          country_code: "ES"
        }
      }
    end

    store = Store.find_by!(user: users(:admin))
    assert store.individual?
    assert_nil store.tax_id
    assert_nil store.postal_code
  end

  private

  def business_params(tax_id:)
    {
      kind: "business",
      name: "Admin's PC Shop",
      description: "A business store used by the onboarding tests.",
      region_id: regions(:madrid).id,
      city: "Madrid",
      country_code: "ES",
      legal_name: "Admin PC Shop SL",
      tax_id: tax_id,
      address_line: "Calle Mayor 1",
      postal_code: "28001",
      phone: "+34 600 000 000",
      website: "https://example.com"
    }
  end
end
