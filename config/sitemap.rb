# frozen_string_literal: true

# Generates one sitemap per locale plus a gzipped sitemap index in
# public/sitemaps. Every URL carries xhtml:link alternates for all six locales
# and x-default (Spanish). Run with `bin/rails pcmarket:sitemaps` or the daily
# Sitemaps::GenerateJob.
require "sitemap_generator"

base = ENV["APP_HOST"].presence || ENV["SITEMAP_HOST"].presence ||
       Rails.application.routes.default_url_options[:host].presence ||
       "localhost:3000"
base = "https://#{base}" unless base.match?(%r{\Ahttps?://})
base = base.sub(%r{\Ahttp://}, "https://") if Rails.env.production?

SitemapGenerator::Sitemap.default_host = base
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
SitemapGenerator::Sitemap.create_index = true
SitemapGenerator::Sitemap.compress = true
SitemapGenerator::Sitemap.verbose = ENV["VERBOSE"].present?

HELPERS = Rails.application.routes.url_helpers
STATIC_PAGES = %w[about how-it-works how-to-sell seller-fees shipping returns].freeze
LEGAL_KINDS = LegalPage.kinds.keys.freeze

# Helpers are mixed into LinkSet because sitemap groups are evaluated with the
# group LinkSet as self, where top-level config methods are not visible.
module PcmarketSitemapEntries
  def localized_path(helper, *args, locale:, **options)
    options = options.merge(locale: locale) unless locale == :es
    HELPERS.public_send(helper, *args, **options)
  end

  def alternate_links(helper, *args, **options)
    alternates = I18n.available_locales.map do |locale|
      { lang: locale.to_s, href: localized_path(helper, *args, locale: locale, **options) }
    end
    alternates << { lang: "x-default", href: localized_path(helper, *args, locale: :es, **options) }
  end

  def add_entry(locale, helper, *args, changefreq:, priority:, lastmod: nil, **options)
    add localized_path(helper, *args, locale: locale, **options),
        alternates: alternate_links(helper, *args, **options),
        lastmod: lastmod,
        changefreq: changefreq,
        priority: priority
  end
end

SitemapGenerator::Interpreter.include(PcmarketSitemapEntries)

SitemapGenerator::Sitemap.create do
  I18n.available_locales.each do |locale|
    group(filename: :"sitemap-#{locale}") do
      add_entry(locale, :root_path, changefreq: "daily", priority: 1.0)

      add_entry(locale, :search_path, changefreq: "daily", priority: 0.7)
      add_entry(locale, :trust_path, changefreq: "monthly", priority: 0.5)
      add_entry(locale, :pc_finder_path, changefreq: "weekly", priority: 0.8)
      add_entry(locale, :help_pages_path, changefreq: "monthly", priority: 0.5)
      STATIC_PAGES.each do |slug|
        add_entry(locale, :help_page_path, slug: slug, changefreq: "monthly", priority: 0.4)
      end
      add_entry(locale, :legal_pages_path, changefreq: "monthly", priority: 0.4)
      LEGAL_KINDS.each do |kind|
        add_entry(locale, :legal_page_path, kind: kind, changefreq: "monthly", priority: 0.3)
      end
      add_entry(locale, :contact_messages_path, changefreq: "yearly", priority: 0.3)

      Game.active.ordered.find_each do |game|
        add_entry(locale, :pc_finder_path, game: game.slug, changefreq: "weekly", priority: 0.6)
      end

      Category.active.ordered.find_each do |category|
        add_entry(locale, :category_path, id: category.to_param,
                  lastmod: category.updated_at, changefreq: "daily", priority: 0.7)
      end

      Store.active.find_each do |store|
        add_entry(locale, :storefront_path, id: store.to_param,
                  lastmod: store.updated_at, changefreq: "weekly", priority: 0.6)
      end

      Listing.visible.find_each do |listing|
        add_entry(locale, :listing_path, id: listing.to_param,
                  lastmod: listing.updated_at, changefreq: "weekly", priority: 0.8)
      end
    end
  end
end
