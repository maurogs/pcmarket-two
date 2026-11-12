# frozen_string_literal: true

SETTINGS = [
  { key: "listings_require_approval", value: true,  value_type: "boolean", group: "listings",    description_key: "settings.listings_require_approval" },
  { key: "commission_percent",        value: 0.0,   value_type: "decimal", group: "commissions", description_key: "settings.commission_percent" },
  { key: "commission_enabled",        value: false, value_type: "boolean", group: "commissions", description_key: "settings.commission_enabled" },
  { key: "featured_listing_price",    value: 4.99,  value_type: "decimal", group: "featured",    description_key: "settings.featured_listing_price" },
  { key: "featured_enabled",          value: false, value_type: "boolean", group: "featured",    description_key: "settings.featured_enabled" },
  { key: "max_images_per_listing",    value: 12,    value_type: "integer", group: "listings",    description_key: "settings.max_images_per_listing" },
  { key: "min_listing_price",         value: 1,     value_type: "integer", group: "listings",    description_key: "settings.min_listing_price" },
  { key: "max_listing_price",         value: 50_000, value_type: "integer", group: "listings",   description_key: "settings.max_listing_price" },
  { key: "buyer_protection_days",     value: 2,     value_type: "integer", group: "orders",      description_key: "settings.buyer_protection_days" },
  { key: "support_email",             value: "support@pcmarket.example", value_type: "string", group: "general", description_key: "settings.support_email" },
  { key: "maintenance_mode",          value: false, value_type: "boolean", group: "general",     description_key: "settings.maintenance_mode" }
].freeze

SETTINGS.each do |attributes|
  Setting.find_or_create_by!(key: attributes[:key]) do |setting|
    setting.assign_attributes(attributes)
  end
end
