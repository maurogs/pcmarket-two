# frozen_string_literal: true

require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "renders the category tree in the desktop mega-menu" do
    get "/en"

    assert_response :success
    assert_includes response.body, 'data-controller="mega-menu"'
    assert_includes response.body, 'data-mega-menu-target="panel"'
    assert_includes response.body, 'href="/en/c/components"'
    assert_includes response.body, 'href="/en/c/graphics-cards"'
    assert_includes response.body, 'href="/en/c/processors"'
    assert_includes response.body, I18n.t("nav.categories.all_category", category: "Components", locale: :en)
  end

  test "renders the same tree as a mobile accordion" do
    get "/en"

    assert_response :success
    assert_includes response.body, '<details class="group rounded-xl">'
    assert_includes response.body, 'href="/en/c/graphics-cards"'
  end

  test "the header search form submits to the search route" do
    get "/en"

    assert_response :success
    assert_includes response.body, 'action="/en/search"'
    assert_includes response.body, 'name="q"'
  end

  test "renders the navigation in the requested locale" do
    get "/es"

    assert_response :success
    assert_includes response.body, "Componentes"
    assert_includes response.body, "Tarjetas gráficas"
  end
end
