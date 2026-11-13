# frozen_string_literal: true

class CreateListings < ActiveRecord::Migration[8.1]
  SEARCHABLE_EXPRESSION = <<~SQL.squish
    setweight(to_tsvector('simple', translate(lower(coalesce(title, '')), 'áàäâãåéèëêíìïîóòöôõúùüûñç', 'aaaaaaeeeeiiiiooooouuuunc')), 'A') ||
    setweight(to_tsvector('simple', translate(lower(coalesce(jsonb_path_query_array(specs, '$.*')::text, '')), 'áàäâãåéèëêíìïîóòöôõúùüûñç', 'aaaaaaeeeeiiiiooooouuuunc')), 'B') ||
    setweight(to_tsvector('simple', translate(lower(coalesce(description, '')), 'áàäâãåéèëêíìïîóòöôõúùüûñç', 'aaaaaaeeeeiiiiooooouuuunc')), 'C')
  SQL

  def up
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    enable_extension "unaccent" unless extension_enabled?("unaccent")

    create_table :listings do |t|
      t.references :store, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string   :title, null: false
      t.text     :description, null: false
      t.string   :slug, null: false
      t.integer  :condition, null: false, default: 0
      t.integer  :price_cents, null: false
      t.integer  :compare_at_price_cents
      t.string   :currency, null: false, default: "EUR"
      t.integer  :quantity, null: false, default: 1
      t.jsonb    :specs, null: false, default: {}
      t.string   :status, null: false, default: "draft"
      t.text     :rejection_reason
      t.datetime :submitted_at
      t.datetime :published_at
      t.datetime :sold_at
      t.datetime :archived_at
      t.string   :country_code, null: false, default: "ES"
      t.references :region, foreign_key: true
      t.string   :city
      t.string   :postal_code
      t.integer  :shipping_mode, null: false, default: 0
      t.integer  :shipping_price_cents, null: false, default: 0
      t.boolean  :free_shipping, null: false, default: false
      t.integer  :handling_days, null: false, default: 3
      t.boolean  :allow_offers, null: false, default: true
      t.datetime :featured_until
      t.integer  :views_count, null: false, default: 0
      t.integer  :favorites_count, null: false, default: 0
      t.virtual  :searchable, type: :tsvector, as: SEARCHABLE_EXPRESSION, stored: true

      t.timestamps
    end

    add_index :listings, :slug, unique: true
    add_index :listings, :searchable, using: :gin
    add_index :listings, :specs, using: :gin, opclass: :jsonb_path_ops
    add_index :listings, %i[category_id published_at],
              where: "status = 'published'",
              order: { published_at: :desc }
    add_index :listings, :price_cents, where: "status = 'published'"
    add_index :listings, :region_id, where: "status = 'published'",
              name: "index_listings_on_region_id_published"
    add_index :listings, %i[store_id status]
    add_index :listings, :published_at,
              where: "status = 'published'",
              order: { published_at: :desc },
              name: "index_listings_on_published_at_published"
    add_index :listings, :title, using: :gin, opclass: :gin_trgm_ops,
              name: "index_listings_on_title_trgm"

    create_table :listing_photos do |t|
      t.references :listing, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :listing_photos, %i[listing_id position]

    create_table :listing_moderations do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.integer :action, null: false, default: 0
      t.text    :reason

      t.timestamps
    end

    add_index :listing_moderations, %i[listing_id created_at]

    create_table :listing_tags do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true, index: false

      t.timestamps
    end

    add_index :listing_tags, %i[listing_id tag_id], unique: true
    add_index :listing_tags, :tag_id
  end

  def down
    drop_table :listing_tags
    drop_table :listing_moderations
    drop_table :listing_photos
    drop_table :listings

    disable_extension "pg_trgm" if extension_enabled?("pg_trgm")
    disable_extension "unaccent" if extension_enabled?("unaccent")
  end
end
