# frozen_string_literal: true

module LegalPagesHelper
  # Renders the stored rich text with stable heading anchors and returns the
  # matching table of contents. The table is built from the same fragment so
  # public pages never show a hard-coded menu that drifts from the copy.
  def legal_page_body_and_toc(page)
    fragment = Nokogiri::HTML::DocumentFragment.parse(page.body.to_s)
    toc = []

    fragment.css("h2, h3").each_with_index do |node, index|
      id = node["id"].presence || "section-#{index + 1}"
      node["id"] = id
      toc << { id: id, title: node.text.squish, level: node.name == "h3" ? 3 : 2 }
    end

    [ fragment.to_html.html_safe, toc ]
  end

  def legal_page_date(page)
    date = page.effective_at || page.published_at
    date ? l(date.to_date, format: :long) : t("legal_pages.public.undated")
  end

  def legal_page_breadcrumbs(page)
    [
      [ t("nav.home"), root_path ],
      [ t("legal_pages.public.index_title"), legal_pages_path ],
      [ page.title, legal_page_path(kind: page.kind) ]
    ]
  end
end
