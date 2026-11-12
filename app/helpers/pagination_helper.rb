# frozen_string_literal: true

module PaginationHelper
  include Pagy::Frontend

  # Pagy's nav, reimplemented with the app's Tailwind utilities, translated
  # labels and rel="prev"/"next" attributes.
  def pagy_nav(pagy)
    return if pagy.pages <= 1

    content_tag(:nav, aria: { label: t("listings.pagination.label") }, class: "mt-8 flex justify-center") do
      content_tag(:ul, class: "flex flex-wrap items-center gap-1.5") do
        safe_join([
          previous_item(pagy),
          *pagy.series.map { |item| series_item(pagy, item) },
          next_item(pagy)
        ])
      end
    end
  end

  private

  def previous_item(pagy)
    content_tag(:li) do
      if pagy.prev
        link_to t("listings.pagination.previous"),
                pagy_url_for(pagy, pagy.prev),
                rel: "prev",
                class: page_link_class
      else
        content_tag(:span, t("listings.pagination.previous"),
                    class: "#{page_link_class} pointer-events-none cursor-not-allowed text-muted",
                    aria: { disabled: "true" })
      end
    end
  end

  def next_item(pagy)
    content_tag(:li) do
      if pagy.next
        link_to t("listings.pagination.next"),
                pagy_url_for(pagy, pagy.next),
                rel: "next",
                class: page_link_class
      else
        content_tag(:span, t("listings.pagination.next"),
                    class: "#{page_link_class} pointer-events-none cursor-not-allowed text-muted",
                    aria: { disabled: "true" })
      end
    end
  end

  def series_item(pagy, item)
    content_tag(:li) do
      case item
      when Integer
        link_to item, pagy_url_for(pagy, item), class: page_link_class
      when String
        content_tag(:span, item,
                    aria: { current: "page" },
                    class: "#{page_link_class} border-primary-600 bg-primary-600 font-semibold text-white")
      when :gap
        content_tag(:span, "…", class: "#{page_link_class} pointer-events-none border-transparent")
      end
    end
  end

  def page_link_class
    "inline-flex h-9 min-w-9 items-center justify-center rounded-lg border border-border bg-surface px-3 text-sm font-medium text-content transition hover:border-primary-400 hover:text-primary-700"
  end
end
