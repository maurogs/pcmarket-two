# frozen_string_literal: true

require "test_helper"

class RobotsAndCanonicalUrlsTest < ActionDispatch::IntegrationTest
  test "robots.txt allows the catalogue, blocks private areas and points to the sitemap" do
    get "/robots.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Allow: /"
    %w[/admin /account /sell /cart /checkout /inbox /api].each do |path|
      assert_includes response.body, "Disallow: #{path}"
    end
    assert_includes response.body, "Disallow: /search?*q="
    assert_includes response.body, "Sitemap: http://www.example.com/sitemaps/sitemap.xml.gz"
    assert_not_includes response.body, "Disallow: /\n"
  end

  test "NOINDEX=1 blocks all crawling for staging" do
    with_env("NOINDEX" => "1") do
      get "/robots.txt"
      assert_response :success
      assert_includes response.body, "Disallow: /"
      assert_not_includes response.body, "Sitemap:"
    end
  end

  test "/es and trailing slashes redirect permanently to canonical paths" do
    get "/es"
    assert_response :moved_permanently
    assert_equal "/", response.location

    get "/es/c/#{categories(:gpus).slug}"
    assert_response :success
    canonical = Nokogiri::HTML(response.body).at_css('link[rel="canonical"]')["href"]
    assert_equal "http://www.example.com/c/#{categories(:gpus).slug}", canonical

    get "/en/trust/"
    assert_response :moved_permanently
    assert_equal "/en/trust", response.location

    get "/en?utm_source=test"
    assert_response :success

    get "/es?utm_source=test"
    assert_response :moved_permanently
    assert_equal "/?utm_source=test", response.location
  end

  test "404, 422 and 500 render the translated branded error page" do
    {
      "/404" => :not_found,
      "/422" => :unprocessable_entity,
      "/500" => :internal_server_error
    }.each do |path, status|
      get path, headers: { "Accept-Language" => "en" }
      assert_response status
      key = { not_found: "not_found", unprocessable_entity: "unprocessable", internal_server_error: "server_error" }.fetch(status)
      doc = Nokogiri::HTML(response.body)
      assert_equal I18n.t("errors.pages.#{key}.title", locale: :en), doc.at_css("h1").text
      assert_equal "/en/search", doc.at_css("form")["action"]
      assert_includes response.body, "PCMarket"
    end
  end

  test "exceptions_app renders branded status pages" do
    { "/404" => 404, "/422" => 422, "/500" => 500 }.each do |path, expected|
      env = Rack::MockRequest.env_for(path, method: "GET", "HTTP_ACCEPT_LANGUAGE" => "en")
      status, headers, body = Rails.application.config.exceptions_app.call(env)
      chunks = []
      body.each { |chunk| chunks << chunk }
      body.close if body.respond_to?(:close)

      assert_equal expected, status
      assert_equal "noindex", headers["X-Robots-Tag"]
      key = { 404 => "not_found", 422 => "unprocessable", 500 => "server_error" }.fetch(expected)
      assert_includes CGI.unescapeHTML(chunks.join), I18n.t("errors.pages.#{key}.title", locale: :en)
    end
  end

  private

  def with_env(values)
    previous = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
