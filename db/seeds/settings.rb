# frozen_string_literal: true

settings = [
  { key: "support_email",             value: "support@pcmarket.example", value_type: "string", group: "general", description_key: "settings.support_email" },
  { key: "api_require_confirmation",  value: true,  value_type: "boolean", group: "general",    description_key: "settings.api_require_confirmation" },
  { key: "listings_require_approval", value: true,  value_type: "boolean", group: "listings",    description_key: "settings.listings_require_approval" },
  { key: "max_images_per_listing",    value: 12,    value_type: "integer", group: "listings",    description_key: "settings.max_images_per_listing" },
  { key: "min_listing_price",         value: 1,     value_type: "integer", group: "listings",    description_key: "settings.min_listing_price" },
  { key: "max_listing_price",         value: 50_000, value_type: "integer", group: "listings",   description_key: "settings.max_listing_price" },
  { key: "commission_percent",        value: 0.0,   value_type: "decimal", group: "commissions", description_key: "settings.commission_percent" },
  { key: "commission_enabled",        value: false, value_type: "boolean", group: "commissions", description_key: "settings.commission_enabled" },
  { key: "featured_listing_price",    value: 4.99,  value_type: "decimal", group: "featured",    description_key: "settings.featured_listing_price" },
  { key: "featured_enabled",          value: false, value_type: "boolean", group: "featured",    description_key: "settings.featured_enabled" },
  { key: "buyer_protection_days",     value: 2,     value_type: "integer", group: "buyer_protection", description_key: "settings.buyer_protection_days" },
  { key: "email_from_name",           value: "PCMarket", value_type: "string", group: "emails", description_key: "settings.email_from_name" },
  { key: "email_reply_to",            value: "support@pcmarket.example", value_type: "string", group: "emails", description_key: "settings.email_reply_to" },
  { key: "maintenance_mode",          value: false, value_type: "boolean", group: "maintenance", description_key: "settings.maintenance_mode" }
].freeze

settings.each do |attributes|
  setting = Setting.find_or_initialize_by(key: attributes[:key])
  if setting.new_record?
    setting.assign_attributes(attributes)
  else
    # Keep the stored value, but refresh the grouping/help metadata so the
    # admin form stays grouped after the Phase 7b schema.
    setting.group = attributes[:group]
    setting.description_key = attributes[:description_key]
  end
  setting.save!
end
