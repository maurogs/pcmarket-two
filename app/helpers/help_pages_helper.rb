# frozen_string_literal: true

module HelpPagesHelper
  def help_page(slug)
    I18n.t("help.pages.#{slug}").deep_symbolize_keys
  end

  def help_sections(page)
    Array(page[:sections])
  end

  def help_faq_categories
    I18n.t("help.faq.categories").deep_symbolize_keys
  end

  def help_breadcrumbs(page)
    [
      [ t("nav.home"), root_path ],
      [ t("help.index.title"), help_pages_path ],
      [ page[:title], nil ]
    ]
  end

  # Fees are only charged while the corresponding feature flag and setting are
  # both enabled. Until then the page says the platform is free.
  def seller_fee_rates
    {
      commission_enabled: Flipper.enabled?(:commissions) &&
                          Setting.get(:commission_enabled, false),
      commission_percent: Setting.get(:commission_percent, 0).to_d,
      featured_enabled: Flipper.enabled?(:featured_listings) &&
                        Setting.get(:featured_enabled, false),
      featured_price_cents: (Setting.get(:featured_listing_price, 0).to_d * 100).round
    }
  end
end
