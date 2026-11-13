# frozen_string_literal: true

module SeoHelper
  OG_LOCALES = {
    es: "es_ES",
    en: "en_GB",
    fr: "fr_FR",
    de: "de_DE",
    it: "it_IT",
    pt: "pt_PT"
  }.freeze

  def default_meta_tags
    {
      site: t("app.name"),
      reverse: true,
      separator: "|",
      description: t("app.tagline"),
      og: {
        site_name: t("app.name"),
        type: "website",
        locale: OG_LOCALES.fetch(I18n.locale, "es_ES"),
        title: t("app.name"),
        url: request.original_url
      },
      twitter: { card: "summary_large_image" }
    }
  end

  def home_meta_tags
    title = t("home.seo.title")
    description = t("home.seo.description")
    canonical = canonicalize_url(root_url)

    {
      title: title,
      description: description,
      canonical: canonical,
      og: {
        type: "website",
        url: canonical,
        title: title,
        description: description
      },
      twitter: { card: "summary_large_image" }
    }
  end

  def organization_json_ld
    {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => t("app.name"),
      "url" => canonicalize_url(root_url),
      "logo" => "#{request.base_url}/icon.png",
      "description" => t("app.tagline")
    }
  end

  # WebSite + SearchAction enables the sitelinks search box.
  def website_json_ld
    {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => t("app.name"),
      "url" => canonicalize_url(root_url),
      "inLanguage" => I18n.locale.to_s,
      "potentialAction" => {
        "@type" => "SearchAction",
        "target" => {
          "@type" => "EntryPoint",
          "urlTemplate" => "#{request.base_url}#{search_path}?q={search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      }
    }
  end

  def hreflang_link_tags
    links = I18n.available_locales.map do |locale|
      tag.link(rel: "alternate", hreflang: locale, href: localized_url(locale))
    end
    links << tag.link(rel: "alternate", hreflang: "x-default",
                      href: localized_url(I18n.default_locale))
    safe_join(links)
  end

  def result_meta_tags(category, search)
    title = result_title(category, search)
    description = result_description(category, search)
    canonical = canonicalize_url(result_canonical(category, search))

    tags = {
      title: title,
      description: description,
      canonical: canonical,
      og: { type: "website", url: canonical, title: title, description: description },
      twitter: { card: "summary_large_image" }
    }
    tags[:robots] = "noindex,follow" if search.filtered?
    tags
  end

  # The quiz landing is indexable. Free-form result URLs are noindex; the
  # single-game preset keeps a stable canonical and its own title.
  def pc_finder_meta_tags(criteria)
    if criteria.preset?
      game = criteria.preset_game
      title = t("pc_finder.seo.preset_title", game: game.name)
      description = t("pc_finder.seo.preset_description", game: game.name)
      canonical = canonicalize_url(pc_finder_url(game: game.slug, locale: I18n.locale))

      {
        title: title,
        description: description,
        canonical: canonical,
        og: { type: "website", url: canonical, title: title, description: description },
        twitter: { card: "summary_large_image" }
      }
    elsif criteria.selected?
      {
        title: t("pc_finder.seo.results_title"),
        description: t("pc_finder.seo.results_description"),
        robots: "noindex,follow"
      }
    else
      title = t("pc_finder.seo.title")
      description = t("pc_finder.seo.description")
      canonical = canonicalize_url(pc_finder_url)

      {
        title: title,
        description: description,
        canonical: canonical,
        og: { type: "website", url: canonical, title: title, description: description },
        twitter: { card: "summary_large_image" }
      }
    end
  end

  def listing_meta_tags(listing)    description = truncate(listing.description.to_s.squish, length: 160)
    canonical = canonicalize_url(listing_url(listing))
    image_url = meta_image_url(listing)

    tags = {
      title: listing.title,
      description: description,
      canonical: canonical,
      og: {
        type: "product",
        url: canonical,
        title: listing.title,
        description: description,
        image: image_url
      }.compact,
      twitter: { card: "summary_large_image" }
    }
    tags[:robots] = "noindex,nofollow" unless listing.publicly_visible?
    tags
  end

  def breadcrumb_json_ld(trail)
    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => trail.each_with_index.map do |(name, url), index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => name,
          "item" => absolute_url(url)
        }
      end
    }
  end

  def item_list_json_ld(listings)
    {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "numberOfItems" => listings.size,
      "itemListElement" => listings.each_with_index.map do |listing, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "url" => canonicalize_url(listing_url(listing)),
          "name" => listing.title
        }
      end
    }
  end

  def store_meta_tags(store)
    title = store.name
    description = truncate(store.description.to_s.squish.presence || t("app.tagline"), length: 160)
    canonical = canonicalize_url(storefront_url(store))

    {
      title: title,
      description: description,
      canonical: canonical,
      og: {
        type: "website",
        url: canonical,
        title: title,
        description: description,
        image: store_image_url(store)
      }.compact,
      twitter: { card: "summary_large_image" }
    }
  end

  def store_json_ld(store)
    type = store.business? ? "Organization" : "Person"
    data = {
      "@context" => "https://schema.org",
      "@type" => type,
      "name" => store.name,
      "url" => canonicalize_url(storefront_url(store)),
      "description" => store.description.presence,
      "image" => store_image_url(store)
    }

    if store.business?
      data["legalName"] = store.legal_name.presence
      data["vatID"] = store.tax_id.presence
      data["address"] = {
        "@type" => "PostalAddress",
        "streetAddress" => store.address_line.presence,
        "postalCode" => store.postal_code.presence,
        "addressLocality" => store.city.presence,
        "addressRegion" => store.province.presence,
        "addressCountry" => store.country_code
      }.compact
    end

    if store.ratings_count.positive?
      data["aggregateRating"] = {
        "@type" => "AggregateRating",
        "ratingValue" => format("%.2f", store.rating_average),
        "reviewCount" => store.ratings_count,
        "bestRating" => 5,
        "worstRating" => 1
      }
    end

    data.compact
  end

  def product_json_ld(listing)
    store = listing.store
    image_url = meta_image_url(listing)

    {
      "@context" => "https://schema.org",
      "@type" => "Product",
      "name" => listing.title,
      "description" => truncate(listing.description.to_s.squish, length: 300),
      "image" => image_url ? [ image_url ] : nil,
      "sku" => listing.slug,
      "itemCondition" => schema_condition(listing.condition),
      "offers" => {
        "@type" => "Offer",
        "url" => canonicalize_url(listing_url(listing)),
        "price" => format("%.2f", listing.price),
        "priceCurrency" => listing.currency,
        "availability" => listing.published? ? "https://schema.org/InStock" : "https://schema.org/SoldOut",
        "itemCondition" => schema_condition(listing.condition),
        "seller" => {
          "@type" => store.business? ? "Organization" : "Person",
          "name" => store.name
        }
      }
    }.compact
  end

  def json_ld_tag(data)
    json = JSON.generate(data).gsub("</", "<\\/")
    content_tag(:script, json.html_safe, type: "application/ld+json")
  end

  def schema_condition(condition)
    case condition.to_s
    when "new_sealed", "new_open_box"
      "https://schema.org/NewCondition"
    when "for_parts"
      "https://schema.org/DamagedCondition"
    else
      "https://schema.org/UsedCondition"
    end
  end

  private

  def result_title(category, search)
    if search.query.present?
      t("listings.index.search_title", query: search.query)
    elsif category
      strip_site_suffix(category.seo_title).presence || category.name
    else
      t("listings.index.title")
    end
  end

  def result_description(category, search)
    if category
      category.seo_description.presence || category.description.presence || t("app.tagline")
    elsif search.query.present?
      t("listings.index.search_description", query: search.query)
    else
      t("app.tagline")
    end
  end

  def result_canonical(category, search)
    if search.filtered?
      category ? category_url(category) : search_url
    elsif search.pagy.page > 1
      request.original_url
    else
      category ? category_url(category) : search_url
    end
  end

  def meta_image_url(listing)
    image = listing.primary_photo&.image
    return unless image&.attached?

    path = url_for(image.variant(:large))
    path.start_with?("http") ? path : "#{request.base_url}#{path}"
  end

  def store_image_url(store)
    return unless store.logo.attached?

    path = url_for(store.logo.variant(resize_to_limit: [ 400, 400 ], format: :webp))
    path.start_with?("http") ? path : "#{request.base_url}#{path}"
  end

  # Builds the canonical/hreflang URL for a locale without relying on
  # url_for's current-locale defaults. Spanish (default) has no /es prefix.
  def localized_url(locale)
    path = request.path.sub(%r{\A/(es|en|fr|de|it|pt)(?=/|\z)}, "")
    path = "/" if path.empty?
    prefix = locale.to_sym == I18n.default_locale ? "" : "/#{locale}"
    query = request.query_string.present? ? "?#{request.query_string}" : ""
    "#{request.base_url}#{prefix}#{path}#{query}"
  end

  def absolute_url(url)
    absolute = url.to_s.start_with?("http") ? url.to_s : "#{request.base_url}#{url}"
    canonicalize_url(absolute)
  end

  # Spanish pages are reachable at /es/... for compatibility but canonicalise
  # to the unprefixed URLs that the site links to.
  def canonicalize_url(url)
    canonical = url.to_s.sub(%r{\A(https?://[^/]+)/es(?=/|\z)}, '\1')
    canonical = "#{canonical}/" if canonical.match?(%r{\Ahttps?://[^/]+\z})
    canonical
  end

  def strip_site_suffix(title)
    title.to_s.sub(/\s*\|\s*#{Regexp.escape(t("app.name"))}\s*\z/, "")
  end
end
