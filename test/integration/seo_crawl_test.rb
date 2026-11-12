# frozen_string_literal: true

require "test_helper"

# Crawls the main public pages and asserts the launch SEO contract: unique
# title, description, canonical, six hreflang alternates + x-default, OG and
# Twitter tags, html lang, a single H1 and BreadcrumbList JSON-LD where a page
# has a breadcrumb.
class SeoCrawlTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:gpus)
    @listing = listings(:published_gpu)
    @store = stores(:confirmed_store)
    @legal_page = LegalPage.create!(
      country_code: "ES", locale: "en", kind: "terms", version: "9.9",
      title: "Crawl terms", status: :published,
      published_at: 1.day.ago, effective_at: 1.day.ago
    )
  end

  test "main public pages carry complete, unique metadata" do
    pages = {
      "home es" => [ "/", "es" ],
      "home en" => [ "/en", "en" ],
      "category" => [ "/en/c/#{@category.slug}", "en" ],
      "listing" => [ "/en/l/#{@listing.slug}", "en" ],
      "search" => [ "/en/search?q=gpu", "en" ],
      "store" => [ "/en/s/#{@store.slug}", "en" ],
      "trust" => [ "/en/trust", "en" ],
      "help" => [ "/en/help/about", "en" ],
      "legal" => [ "/en/legal/#{@legal_page.kind}", "en" ],
      "pc finder" => [ "/en/pc-finder", "en" ],
      "contact" => [ "/en/contact", "en" ]
    }

    titles = {}

    pages.each do |name, (path, language)|
      get path
      assert_response :success, "#{name} (#{path}) did not render"
      doc = Nokogiri::HTML(response.body)

      html = doc.at_css("html")
      assert_equal language, html["lang"], "#{name}: wrong html lang"

      title = doc.at_css("head title")&.text.to_s.strip
      assert title.present?, "#{name}: missing title"
      assert_operator title.length, :<=, 70, "#{name}: title too long (#{title.length})"
      assert_not_includes titles.values, title, "#{name}: duplicate title #{title.inspect}"
      titles[name] = title

      description = doc.at_css('meta[name="description"]')&.[]("content").to_s.strip
      assert description.present?, "#{name}: missing meta description"
      assert_operator description.length, :>=, 20, "#{name}: description too short"

      canonical = doc.at_css('link[rel="canonical"]')&.[]("href").to_s
      assert canonical.start_with?("http"), "#{name}: missing canonical"

      alternates = doc.css('link[rel="alternate"][hreflang]').map { |node| node["hreflang"] }
      assert_equal %w[de en es fr it pt x-default].sort, alternates.sort, "#{name}: hreflang set"

      assert doc.at_css('meta[property="og:title"]')&.[]("content").present?, "#{name}: og:title"
      assert doc.at_css('meta[property="og:url"]')&.[]("content").present?, "#{name}: og:url"
      assert_equal "summary_large_image", doc.at_css('meta[name="twitter:card"]')&.[]("content"), "#{name}: twitter card"

      assert_equal 1, doc.css("h1").size, "#{name}: expected exactly one H1"
    end
  end

  test "breadcrumb JSON-LD is present on navigable pages" do
    %W[/en/c/#{@category.slug} /en/l/#{@listing.slug} /en/s/#{@store.slug}].each do |path|
      get path
      assert_response :success
      json = Nokogiri::HTML(response.body).css('script[type="application/ld+json"]').map(&:text).join("\n")
      assert_includes json, "BreadcrumbList", "#{path}: missing BreadcrumbList"
    end
  end

  test "Spanish URLs are canonical without the /es prefix" do
    get "/"
    assert_response :success
    doc = Nokogiri::HTML(response.body)
    assert_equal "http://www.example.com/", doc.at_css('link[rel="canonical"]')["href"]
    assert_equal "http://www.example.com/",
                 doc.at_css('link[rel="alternate"][hreflang="es"]')["href"]

    get "/en"
    assert_response :success
    doc = Nokogiri::HTML(response.body)
    assert_equal "http://www.example.com/en", doc.at_css('link[rel="canonical"]')["href"]
  end
end
