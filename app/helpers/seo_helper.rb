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
        locale: OG_LOCALES.fetch(I18n.locale, "es_ES")
      },
      twitter: { card: "summary_large_image" }
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
    canonical = result_canonical(category, search)

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

  def listing_meta_tags(listing)
    description = truncate(listing.description.to_s.squish, length: 160)
    canonical = listing_url(listing)
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
          "url" => listing_url(listing),
          "name" => listing.title
        }
      end
    }
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
        "url" => listing_url(listing),
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

  def localized_url(locale)
    url_for(request.path_parameters.merge(request.query_parameters).merge(locale: locale, only_path: false))
  end

  def absolute_url(url)
    url.to_s.start_with?("http") ? url : "#{request.base_url}#{url}"
  end

  def strip_site_suffix(title)
    title.to_s.sub(/\s*\|\s*#{Regexp.escape(t("app.name"))}\s*\z/, "")
  end
end
