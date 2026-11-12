# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_200100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id"
    t.string "full_name", null: false
    t.string "line1", null: false
    t.string "line2"
    t.string "city", null: false
    t.bigint "region_id"
    t.string "postal_code", null: false
    t.string "country_code", default: "ES", null: false
    t.string "phone", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_addresses_on_region_id"
    t.index ["user_id", "default"], name: "index_addresses_on_user_id_and_default"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "admin_audit_logs", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.jsonb "changes_data", default: {}, null: false
    t.string "ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["action", "created_at"], name: "index_admin_audit_logs_on_action_and_created_at"
    t.index ["actor_id"], name: "index_admin_audit_logs_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_admin_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_admin_audit_logs_on_created_at"
  end

  create_table "attribute_definitions", force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "name", default: {}, null: false
    t.string "group"
    t.integer "input_type", default: 0, null: false
    t.string "unit"
    t.boolean "filterable", default: true, null: false
    t.boolean "show_on_card", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_attribute_definitions_on_active"
    t.index ["group", "position"], name: "index_attribute_definitions_on_group_and_position"
    t.index ["key"], name: "index_attribute_definitions_on_key", unique: true
  end

  create_table "attribute_options", force: :cascade do |t|
    t.bigint "attribute_definition_id", null: false
    t.string "value", null: false
    t.jsonb "label", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.boolean "popular", default: true, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attribute_definition_id", "position"], name: "idx_on_attribute_definition_id_position_04388d48f8"
    t.index ["attribute_definition_id", "value"], name: "index_attribute_options_on_attribute_definition_id_and_value", unique: true
    t.index ["attribute_definition_id"], name: "index_attribute_options_on_attribute_definition_id"
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocker_id", null: false
    t.bigint "blocked_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "listing_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "offer_id"
    t.integer "unit_price_cents"
    t.index ["cart_id", "listing_id"], name: "index_cart_items_on_cart_id_and_listing_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["listing_id"], name: "index_cart_items_on_listing_id"
    t.index ["offer_id"], name: "index_cart_items_on_offer_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_carts_on_token", unique: true
    t.index ["user_id"], name: "index_carts_on_user_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "parent_id"
    t.jsonb "name", default: {}, null: false
    t.jsonb "description", default: {}, null: false
    t.jsonb "seo_title", default: {}, null: false
    t.jsonb "seo_description", default: {}, null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "icon"
    t.integer "depth", default: 0, null: false
    t.integer "listings_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_categories_on_active"
    t.index ["parent_id", "position"], name: "index_categories_on_parent_id_and_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "category_attributes", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "attribute_definition_id", null: false
    t.boolean "required", default: false, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attribute_definition_id"], name: "index_category_attributes_on_attribute_definition_id"
    t.index ["category_id", "attribute_definition_id"], name: "idx_on_category_id_attribute_definition_id_58e88a2133", unique: true
    t.index ["category_id"], name: "index_category_attributes_on_category_id"
  end

  create_table "checkouts", force: :cascade do |t|
    t.bigint "buyer_id"
    t.string "status", default: "pending", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "shipping_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "payment_intent_id"
    t.datetime "expires_at"
    t.jsonb "shipping_address", default: {}, null: false
    t.string "email"
    t.string "idempotency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_client_secret"
    t.index ["buyer_id"], name: "index_checkouts_on_buyer_id"
    t.index ["expires_at"], name: "index_checkouts_on_expires_at"
    t.index ["idempotency_key"], name: "index_checkouts_on_idempotency_key", unique: true
    t.index ["status"], name: "index_checkouts_on_status"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "listing_id"
    t.bigint "buyer_id", null: false
    t.bigint "seller_id", null: false
    t.bigint "store_id", null: false
    t.datetime "last_message_at"
    t.integer "buyer_unread_count", default: 0, null: false
    t.integer "seller_unread_count", default: 0, null: false
    t.boolean "buyer_archived", default: false, null: false
    t.boolean "seller_archived", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "last_message_at"], name: "index_conversations_on_buyer_id_and_last_message_at"
    t.index ["buyer_id"], name: "index_conversations_on_buyer_id"
    t.index ["listing_id", "buyer_id"], name: "index_conversations_on_listing_id_and_buyer_id", unique: true
    t.index ["listing_id"], name: "index_conversations_on_listing_id"
    t.index ["seller_id", "last_message_at"], name: "index_conversations_on_seller_id_and_last_message_at"
    t.index ["seller_id"], name: "index_conversations_on_seller_id"
    t.index ["store_id", "buyer_id"], name: "index_conversations_on_store_and_buyer_without_listing", unique: true, where: "(listing_id IS NULL)"
    t.index ["store_id"], name: "index_conversations_on_store_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "code", null: false
    t.boolean "active", default: false, null: false
    t.string "default_locale", default: "en", null: false
    t.string "currency", default: "EUR", null: false
    t.decimal "vat_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["position"], name: "index_countries_on_position"
  end

  create_table "favourites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "listing_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_favourites_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_favourites_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_favourites_on_user_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "key", null: false
    t.string "description_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feature_flags_on_key", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "store_id", null: false
    t.datetime "last_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "store_id"], name: "index_follows_on_follower_id_and_store_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.index ["store_id", "last_notified_at"], name: "index_follows_on_store_id_and_last_notified_at"
    t.index ["store_id"], name: "index_follows_on_store_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "legal_pages", force: :cascade do |t|
    t.string "country_code", null: false
    t.string "locale", null: false
    t.integer "kind", default: 0, null: false
    t.string "title", null: false
    t.string "version", null: false
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.datetime "effective_at"
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "locale", "kind", "status"], name: "index_legal_pages_on_country_locale_kind_status"
    t.index ["country_code", "locale", "kind", "version"], name: "index_legal_pages_on_country_locale_kind_version", unique: true
  end

  create_table "listing_moderations", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "moderator_id", null: false
    t.integer "action", default: 0, null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "created_at"], name: "index_listing_moderations_on_listing_id_and_created_at"
    t.index ["listing_id"], name: "index_listing_moderations_on_listing_id"
    t.index ["moderator_id"], name: "index_listing_moderations_on_moderator_id"
  end

  create_table "listing_photos", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "position"], name: "index_listing_photos_on_listing_id_and_position"
    t.index ["listing_id"], name: "index_listing_photos_on_listing_id"
  end

  create_table "listing_tags", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id", "tag_id"], name: "index_listing_tags_on_listing_id_and_tag_id", unique: true
    t.index ["listing_id"], name: "index_listing_tags_on_listing_id"
    t.index ["tag_id"], name: "index_listing_tags_on_tag_id"
  end

  create_table "listing_views", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.date "date", null: false
    t.integer "views", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_listing_views_on_date"
    t.index ["listing_id", "date"], name: "index_listing_views_on_listing_id_and_date", unique: true
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "title"
    t.text "description"
    t.string "slug", null: false
    t.integer "condition", default: 0, null: false
    t.integer "price_cents"
    t.integer "compare_at_price_cents"
    t.string "currency", default: "EUR", null: false
    t.integer "quantity", default: 1, null: false
    t.jsonb "specs", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.text "rejection_reason"
    t.datetime "submitted_at"
    t.datetime "published_at"
    t.datetime "sold_at"
    t.datetime "archived_at"
    t.string "country_code", default: "ES", null: false
    t.bigint "region_id"
    t.string "city"
    t.string "postal_code"
    t.integer "shipping_mode", default: 0, null: false
    t.integer "shipping_price_cents", default: 0, null: false
    t.boolean "free_shipping", default: false, null: false
    t.integer "handling_days", default: 3, null: false
    t.boolean "allow_offers", default: true, null: false
    t.datetime "featured_until"
    t.integer "views_count", default: 0, null: false
    t.integer "favorites_count", default: 0, null: false
    t.virtual "searchable", type: :tsvector, as: "((setweight(to_tsvector('simple'::regconfig, translate(lower((COALESCE(title, ''::character varying))::text), 'áàäâãåéèëêíìïîóòöôõúùüûñç'::text, 'aaaaaaeeeeiiiiooooouuuunc'::text)), 'A'::\"char\") || setweight(to_tsvector('simple'::regconfig, translate(lower(COALESCE((jsonb_path_query_array(specs, '$.*'::jsonpath))::text, ''::text)), 'áàäâãåéèëêíìïîóòöôõúùüûñç'::text, 'aaaaaaeeeeiiiiooooouuuunc'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, translate(lower(COALESCE(description, ''::text)), 'áàäâãåéèëêíìïîóòöôõúùüûñç'::text, 'aaaaaaeeeeiiiiooooouuuunc'::text)), 'C'::\"char\"))", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "published_at"], name: "index_listings_on_category_id_and_published_at", order: { published_at: :desc }, where: "((status)::text = 'published'::text)"
    t.index ["category_id"], name: "index_listings_on_category_id"
    t.index ["price_cents"], name: "index_listings_on_price_cents", where: "((status)::text = 'published'::text)"
    t.index ["published_at"], name: "index_listings_on_published_at_published", order: :desc, where: "((status)::text = 'published'::text)"
    t.index ["region_id"], name: "index_listings_on_region_id"
    t.index ["region_id"], name: "index_listings_on_region_id_published", where: "((status)::text = 'published'::text)"
    t.index ["searchable"], name: "index_listings_on_searchable", using: :gin
    t.index ["slug"], name: "index_listings_on_slug", unique: true
    t.index ["specs"], name: "index_listings_on_specs", opclass: :jsonb_path_ops, using: :gin
    t.index ["store_id", "status"], name: "index_listings_on_store_id_and_status"
    t.index ["store_id"], name: "index_listings_on_store_id"
    t.index ["title"], name: "index_listings_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.integer "kind", default: 0, null: false
    t.datetime "read_at"
    t.datetime "hidden_at"
    t.boolean "safety_flagged", default: false, null: false
    t.jsonb "safety_reasons", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id", "created_at"], name: "index_messages_on_sender_id_and_created_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.boolean "in_app", default: true, null: false
    t.boolean "email", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "kind"], name: "index_notification_preferences_on_user_id_and_kind", unique: true
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.string "kind", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.jsonb "params", default: {}, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_notifications_on_kind"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "read_at", "created_at"], name: "index_notifications_on_recipient_id_and_read_at_and_created_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "offers", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.bigint "buyer_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "offerer_id", null: false
    t.bigint "counter_offer_id"
    t.integer "amount_cents", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at"
    t.datetime "expiry_reminder_sent_at"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_offers_on_buyer_id"
    t.index ["conversation_id"], name: "index_offers_on_conversation_id"
    t.index ["counter_offer_id"], name: "index_offers_on_counter_offer_id"
    t.index ["listing_id", "buyer_id"], name: "index_offers_on_listing_and_buyer_pending", unique: true, where: "(((status)::text = 'pending'::text) AND (counter_offer_id IS NULL))"
    t.index ["listing_id"], name: "index_offers_on_listing_id"
    t.index ["offerer_id"], name: "index_offers_on_offerer_id"
    t.index ["status", "expires_at"], name: "index_offers_on_status_and_expires_at"
  end

  create_table "order_events", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "actor_id"
    t.string "event", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_order_events_on_actor_id"
    t.index ["order_id", "created_at"], name: "index_order_events_on_order_id_and_created_at"
    t.index ["order_id"], name: "index_order_events_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "listing_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.integer "shipping_cents", default: 0, null: false
    t.string "title", null: false
    t.string "seller_name", null: false
    t.string "photo_url"
    t.jsonb "specs", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["listing_id"], name: "index_order_items_on_listing_id"
    t.index ["order_id", "listing_id"], name: "index_order_items_on_order_id_and_listing_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "order_notes", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_order_notes_on_author_id"
    t.index ["order_id", "created_at"], name: "index_order_notes_on_order_id_and_created_at"
    t.index ["order_id"], name: "index_order_notes_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "checkout_id", null: false
    t.bigint "buyer_id"
    t.bigint "store_id", null: false
    t.string "number"
    t.string "status", default: "pending_payment", null: false
    t.integer "fulfilment", default: 0, null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "shipping_cents", default: 0, null: false
    t.integer "commission_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "currency", default: "EUR", null: false
    t.string "tracking_carrier"
    t.string "tracking_number"
    t.datetime "paid_at"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.datetime "buyer_protection_ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "created_at"], name: "index_orders_on_buyer_id_and_created_at"
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["checkout_id", "store_id"], name: "index_orders_on_checkout_id_and_store_id", unique: true
    t.index ["checkout_id"], name: "index_orders_on_checkout_id"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["store_id", "status"], name: "index_orders_on_store_id_and_status"
    t.index ["store_id"], name: "index_orders_on_store_id"
  end

  create_table "payouts", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "store_id", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "stripe_transfer_id"
    t.string "status", default: "pending", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payouts_on_order_id", unique: true
    t.index ["store_id"], name: "index_payouts_on_store_id"
    t.index ["stripe_transfer_id"], name: "index_payouts_on_stripe_transfer_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "country_code", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "code"], name: "index_regions_on_country_code_and_code", unique: true
    t.index ["country_code"], name: "index_regions_on_country_code"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "reporter_id"
    t.string "reporter_email"
    t.string "reportable_type", null: false
    t.bigint "reportable_id", null: false
    t.integer "reason", null: false
    t.text "details", null: false
    t.integer "status", default: 0, null: false
    t.text "resolution_note"
    t.bigint "handled_by_id"
    t.datetime "handled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["handled_by_id"], name: "index_reports_on_handled_by_id"
    t.index ["reason"], name: "index_reports_on_reason"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["status", "created_at"], name: "index_reports_on_status_and_created_at"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "reviewer_id", null: false
    t.bigint "store_id", null: false
    t.integer "rating", null: false
    t.text "body", null: false
    t.text "seller_reply"
    t.datetime "seller_replied_at"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_reviews_on_order_id", unique: true
    t.index ["reviewer_id", "created_at"], name: "index_reviews_on_reviewer_id_and_created_at"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["store_id", "status", "created_at"], name: "index_reviews_on_store_id_and_status_and_created_at"
    t.index ["store_id"], name: "index_reviews_on_store_id"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.jsonb "query_params", default: {}, null: false
    t.bigint "category_id"
    t.boolean "email_alerts", default: true, null: false
    t.string "frequency", default: "daily", null: false
    t.datetime "last_notified_at"
    t.bigint "last_matched_listing_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_saved_searches_on_category_id"
    t.index ["last_matched_listing_id"], name: "index_saved_searches_on_last_matched_listing_id"
    t.index ["user_id", "frequency"], name: "index_saved_searches_on_user_id_and_frequency"
    t.index ["user_id"], name: "index_saved_searches_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "value"
    t.string "value_type", default: "string", null: false
    t.string "group"
    t.string "description_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group"], name: "index_settings_on_group"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "stores", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "kind", default: 0, null: false
    t.string "legal_name"
    t.string "tax_id"
    t.string "address_line"
    t.string "city"
    t.string "province"
    t.string "postal_code"
    t.string "country_code", default: "ES", null: false
    t.string "phone"
    t.string "website"
    t.datetime "verified_at"
    t.boolean "vacation_mode", default: false, null: false
    t.text "vacation_message"
    t.boolean "allow_offers_default", default: true, null: false
    t.integer "status", default: 0, null: false
    t.decimal "rating_average", precision: 3, scale: 2, default: "0.0", null: false
    t.integer "ratings_count", default: 0, null: false
    t.integer "listings_count", default: 0, null: false
    t.integer "sales_count", default: 0, null: false
    t.integer "followers_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "region_id"
    t.string "stripe_account_id"
    t.boolean "payouts_enabled", default: false, null: false
    t.boolean "charges_enabled", default: false, null: false
    t.boolean "details_submitted", default: false, null: false
    t.jsonb "requirements", default: {}, null: false
    t.date "vacation_until"
    t.text "return_policy"
    t.text "shipping_policy"
    t.integer "handling_days", default: 3, null: false
    t.index ["country_code"], name: "index_stores_on_country_code"
    t.index ["region_id"], name: "index_stores_on_region_id"
    t.index ["slug"], name: "index_stores_on_slug", unique: true
    t.index ["status"], name: "index_stores_on_status"
    t.index ["stripe_account_id"], name: "index_stores_on_stripe_account_id", unique: true
    t.index ["user_id"], name: "index_stores_on_user_id", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.jsonb "name", default: {}, null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "colour"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "position"], name: "index_tags_on_kind_and_position"
    t.index ["kind", "slug"], name: "index_tags_on_kind_and_slug", unique: true
    t.index ["kind"], name: "index_tags_on_kind"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.citext "username", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.string "locale", default: "es", null: false
    t.string "country_code", default: "ES", null: false
    t.datetime "banned_at"
    t.string "ban_reason"
    t.datetime "deleted_at"
    t.string "provider"
    t.string "uid"
    t.boolean "marketing_opt_in", default: false, null: false
    t.datetime "terms_accepted_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unconfirmed_email"], name: "index_users_on_unconfirmed_email"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "event_id", null: false
    t.string "type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "event_id"], name: "index_webhook_events_on_provider_and_event_id", unique: true
    t.index ["type"], name: "index_webhook_events_on_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "regions"
  add_foreign_key "addresses", "users"
  add_foreign_key "admin_audit_logs", "users", column: "actor_id"
  add_foreign_key "attribute_options", "attribute_definitions"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "listings"
  add_foreign_key "cart_items", "offers"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "category_attributes", "attribute_definitions"
  add_foreign_key "category_attributes", "categories"
  add_foreign_key "checkouts", "users", column: "buyer_id"
  add_foreign_key "conversations", "listings"
  add_foreign_key "conversations", "stores"
  add_foreign_key "conversations", "users", column: "buyer_id"
  add_foreign_key "conversations", "users", column: "seller_id"
  add_foreign_key "favourites", "listings"
  add_foreign_key "favourites", "users"
  add_foreign_key "follows", "stores"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "legal_pages", "countries", column: "country_code", primary_key: "code"
  add_foreign_key "listing_moderations", "listings"
  add_foreign_key "listing_moderations", "users", column: "moderator_id"
  add_foreign_key "listing_photos", "listings"
  add_foreign_key "listing_tags", "listings"
  add_foreign_key "listing_tags", "tags"
  add_foreign_key "listing_views", "listings"
  add_foreign_key "listings", "categories"
  add_foreign_key "listings", "regions"
  add_foreign_key "listings", "stores"
  add_foreign_key "listings", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "offers", "conversations"
  add_foreign_key "offers", "listings"
  add_foreign_key "offers", "offers", column: "counter_offer_id"
  add_foreign_key "offers", "users", column: "buyer_id"
  add_foreign_key "offers", "users", column: "offerer_id"
  add_foreign_key "order_events", "orders"
  add_foreign_key "order_events", "users", column: "actor_id"
  add_foreign_key "order_items", "listings"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_notes", "orders"
  add_foreign_key "order_notes", "users", column: "author_id"
  add_foreign_key "orders", "checkouts"
  add_foreign_key "orders", "stores"
  add_foreign_key "orders", "users", column: "buyer_id"
  add_foreign_key "payouts", "orders"
  add_foreign_key "payouts", "stores"
  add_foreign_key "regions", "countries", column: "country_code", primary_key: "code"
  add_foreign_key "reports", "users", column: "handled_by_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reviews", "orders"
  add_foreign_key "reviews", "stores"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "saved_searches", "categories"
  add_foreign_key "saved_searches", "users"
  add_foreign_key "stores", "regions"
  add_foreign_key "stores", "users"
end
