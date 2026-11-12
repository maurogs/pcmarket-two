# frozen_string_literal: true

require "test_helper"

# Public result pages are shared between visitors, so their HTTP and fragment
# caches must never include session-specific data (CSRF tokens, favourite
# state, emails). User-specific controls render outside the cached fragments.
class PublicCachingTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:gpus)
    @listing = listings(:published_gpu)
    @user = users(:seller_two)
    Favourite.create!(user: @user, listing: @listing)
    @path = "/c/#{@category.slug}"
  end

  test "anonymous result pages are publicly cacheable and signed-in ones are not" do
    get @path
    assert_response :success
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Cache-Control"], "max-age=60"

    sign_in @user
    get @path
    assert_response :success
    assert_not_includes response.headers["Cache-Control"].to_s, "public"
  end

  test "fragment caches never contain CSRF tokens or per-user favourite state" do
    member = open_session
    sign_in_session(member, @user)

    with_fragment_caching(forgery: true) do
      visitor = open_session
      visitor.get @path
      assert_equal 200, visitor.response.status
      anonymous_token = csrf_token(visitor.response.body)
      assert anonymous_token.present?
      assert_includes visitor.response.body, 'aria-pressed="false"'

      member.get @path
      assert_equal 200, member.response.status
      signed_in_token = csrf_token(member.response.body)
      assert signed_in_token.present?
      assert_not_equal anonymous_token, signed_in_token
      assert_includes member.response.body, 'aria-pressed="true"'

      # A second anonymous visitor reuses the fragment cache filled by the
      # first visitor and by the signed-in member.
      second_visitor = open_session
      second_visitor.get @path
      assert_equal 200, second_visitor.response.status
      assert_not_includes second_visitor.response.body, anonymous_token
      assert_not_includes second_visitor.response.body, signed_in_token
      assert_not_includes second_visitor.response.body, @user.email
      assert_includes second_visitor.response.body, 'aria-pressed="false"'
    end
  end

  test "search result cache keys ignore the visitor identity" do
    member = open_session
    sign_in_session(member, @user)

    with_fragment_caching(forgery: true) do
      visitor = open_session
      visitor.get "/search?q=rtx"
      assert_equal 200, visitor.response.status
      assert_includes visitor.response.body, @listing.title

      member.get "/search?q=rtx"
      assert_equal 200, member.response.status

      second_visitor = open_session
      second_visitor.get "/search?q=rtx"
      assert_equal 200, second_visitor.response.status
      assert_includes second_visitor.response.body, @listing.title
      assert_not_includes second_visitor.response.body, @user.email
    end
  end

  test "home and storefront fragments do not leak another session's CSRF token" do
    store = stores(:confirmed_store)
    sold = listings(:sold_gpu)

    with_fragment_caching(forgery: true) do
      first = open_session
      first.get "/"
      assert_equal 200, first.response.status
      first_token = csrf_token(first.response.body)
      assert first_token.present?
      assert_includes first.response.body, I18n.t("favourites.button.sign_in")

      second = open_session
      second.get "/"
      assert_equal 200, second.response.status
      assert_not_includes second.response.body, first_token

      first.get "/s/#{store.slug}?tab=listings"
      assert_equal 200, first.response.status
      assert_includes first.response.body, sold.title
      first_store_token = csrf_token(first.response.body)

      second.get "/s/#{store.slug}?tab=listings"
      assert_equal 200, second.response.status
      assert_not_includes second.response.body, first_store_token
    end
  end

  private

  def sign_in_session(session, user)
    session.post user_session_path, params: { user: { email: user.email, password: "Password123!" } }
    assert_includes [ 302, 303 ], session.response.status
  end

  def csrf_token(html)
    Nokogiri::HTML(html).at_css('meta[name="csrf-token"]')&.[]("content")
  end

  def with_fragment_caching(forgery: false)
    previous_cache = Rails.cache
    previous_controller_cache = ActionController::Base.cache_store
    previous_perform_caching = ActionController::Base.perform_caching
    previous_forgery = ActionController::Base.allow_forgery_protection

    store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache = store
    ActionController::Base.cache_store = store
    ActionController::Base.perform_caching = true
    ActionController::Base.allow_forgery_protection = forgery
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous_forgery
    ActionController::Base.perform_caching = previous_perform_caching
    ActionController::Base.cache_store = previous_controller_cache
    Rails.cache = previous_cache
  end
end
