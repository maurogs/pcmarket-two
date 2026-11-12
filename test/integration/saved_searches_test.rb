# frozen_string_literal: true

require "test_helper"

class SavedSearchesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:moderator)
    @category = categories(:gpus)
  end

  test "saving a search from a category page stores normalized filters" do
    sign_in @user
    get category_path(@category, locale: :en)
    assert_response :success
    assert_select "input[name='saved_search[name]']"

    query_params = {
      "min_price" => "100",
      "max_price" => "400",
      "page" => "2",
      "sort" => "price_asc"
    }.to_json

    assert_difference -> { SavedSearch.count }, 1 do
      post saved_searches_path(locale: :en),
           params: {
             saved_search: {
               name: "RTX under 400",
               category_id: @category.id,
               query_params_json: query_params
             }
           },
           headers: { "Referer" => category_path(@category, locale: :en) }
    end

    assert_redirected_to category_path(@category, locale: :en)

    search = @user.saved_searches.order(:id).last
    assert_equal "RTX under 400", search.name
    assert_equal @category, search.category
    assert_equal 100.0, search.query_params["min_price"]
    assert_equal 400.0, search.query_params["max_price"]
    assert_equal "price_asc", search.query_params["sort"]
    assert_not search.query_params.key?("page")
  end

  test "the manage page renames, toggles alerts, changes frequency and deletes" do
    search = SavedSearch.create!(user: @user, name: "Old name", category: @category,
                                 frequency: "instant", query_params: {})
    sign_in @user

    patch saved_search_path(search, locale: :en),
          params: { saved_search: { name: "New name", email_alerts: "0", frequency: "weekly" } }

    assert_redirected_to saved_searches_path(locale: :en)
    search.reload
    assert_equal "New name", search.name
    assert_not search.email_alerts?
    assert_equal "weekly", search.frequency

    get saved_searches_path(locale: :en)
    assert_response :success
    assert_includes response.body, I18n.t("saved_searches.card.view_results", locale: :en)
    assert_includes response.body, search_path(search.to_search_params.merge(locale: :en))

    assert_difference -> { SavedSearch.count }, -1 do
      delete saved_search_path(search, locale: :en)
    end
    assert_redirected_to saved_searches_path(locale: :en)
  end

  test "the cap error is flashed with a translated message" do
    SavedSearch::MAX_PER_USER.times do |index|
      SavedSearch.create!(user: @user, name: "Search #{index}", query_params: {})
    end
    sign_in @user

    assert_no_difference -> { SavedSearch.count } do
      post saved_searches_path(locale: :en),
           params: { saved_search: { name: "One too many", query_params_json: "{}" } }
    end

    assert_redirected_to saved_searches_path(locale: :en)
    assert_equal I18n.t("saved_searches.errors.limit_reached",
                        max: SavedSearch::MAX_PER_USER, locale: :en),
                 flash[:alert]
  end

  test "anonymous visitors see the save link pointing to sign in" do
    get category_path(@category, locale: :en)

    assert_response :success
    assert_select "a[href=?]", new_user_session_path(locale: :en),
                  text: I18n.t("saved_searches.save", locale: :en)
  end
end
