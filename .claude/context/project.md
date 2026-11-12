# Project Context

## Overview
PCMarket is a Rails 8.1 marketplace for buying and selling PC parts. This document tracks architectural decisions, the current code map and open items.

## Stack
- Ruby 4.0.9, Rails 8.1.4, PostgreSQL
- Propshaft asset pipeline, importmap, Hotwire
- Tailwind CSS via `tailwindcss-rails` (source in `app/assets/tailwind/application.css`, compiled to `app/assets/builds/tailwind.css`)
- I18n with six locales: es (default), en, fr, de, it, pt
- Devise + devise-i18n, OmniAuth Google, Pundit, Pagy, pg_search, FriendlyId, MetaTags, SitemapGenerator, Flipper, Mobility, AASM, Stripe, Rack::Attack, ActiveStorageValidations
- i18n-tasks and Faker in development/test; letter_opener_web in development

## Decisions
- Spanish is the default locale; the fallback chain is English then Spanish (`config.i18n.fallbacks = [ :en, :es ]`), also used by Mobility.
- Time zone is `Madrid`.
- English copy uses British spelling (en-GB): colour, favourites, basket.
- All user-facing strings live in `config/locales/*.yml` with an identical nested key structure rooted at each language code.
- Locale is detected in `app/controllers/concerns/localization.rb` with this priority: `params[:locale]`, `cookies[:locale]`, `Accept-Language`, `I18n.default_locale`; validation uses `I18n.available_locales` (the old `SUPPORTED_LOCALES` constant was removed in Phase 0b).
- The chosen locale is persisted in `cookies[:locale]` for one year.
- HTML routes live under an optional locale scope `scope "(:locale)", locale: /es|en|fr|de|it|pt/`; the health check and OmniAuth callbacks stay outside it.
- `locale.names.*` keys are referenced dynamically by the locale switcher and are explicitly ignored by i18n-tasks. `nav.categories.*`, `countries.*`, `settings.*`, `devise.failure.*` and `activerecord.*` are ignored for the same reason (dynamic lookups, admin UI and Devise runtime resolution).
- Design tokens live in `app/assets/tailwind/application.css` under `@theme`: primary (indigo/violet, 50–900), accent (warm coral), semantic surface/canvas/content/muted/border, success/warning/danger, and radius/font tokens. Inter is loaded from Google Fonts with `display=swap`.
- Dark mode uses the class strategy (`@custom-variant dark (&:where(.dark, .dark *))`); `.dark` overrides the same semantic CSS variables, so no `dark:` variant is needed for surfaces. An inline script in `<head>` applies the stored/system theme before paint to avoid a flash.
- The shell is split into `app/views/shared/` partials: `_announcement_bar`, `_header`, `_main_nav`, `_footer`, `_flash`, `_back_to_top`, plus `_search_form`. Desktop and drawer navigation share `_main_nav` via a `mobile` local.
- Stimulus controllers in `app/javascript/controllers/`: `theme`, `drawer`, `dropdown` and `flash`. The mobile drawer is an off-canvas dialog with Escape/scroll-lock handling; the dropdown is a reusable accessible menu.
- Tailwind is linked through `stylesheet_link_tag :app`, which includes all CSS under `app/assets` (application.css and the compiled tailwind.css).
- The Tailwind watcher runs as `tailwindcss:watch[always]` in `Procfile.dev` so it stays alive when stdin is closed (non-interactive shells/CI).
- Flipper uses the ActiveRecord adapter (`config/initializers/flipper.rb`); its `flipper_features` and `flipper_gates` tables are created by `db/migrate/20261112085830_create_flipper_tables.rb`. The UI is mounted at `/admin/flipper` behind `authenticate :user, ->(user) { user.admin? }`.
- Authentication is Devise with database_authenticatable, registerable, recoverable, rememberable, validatable, confirmable, lockable, trackable and omniauthable (google_oauth2).
- `username` is a `citext` column with a unique index, 3–30 characters and `[a-zA-Z0-9_-]`; it is required at registration (no auto-suggestion).
- `User#active_for_authentication?` returns false for banned (`banned_at`) and soft-deleted (`deleted_at`) accounts; `inactive_message` returns `:banned` or `:deleted` with translations in `devise.failure.*`.
- Google OAuth is registered only when both the client id and secret exist in credentials (`google.client_id`/`google.client_secret`) or `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET`. The login button and OAuth routes are absent otherwise.
- OmniAuth callbacks live outside the locale scope. User creation/linking is isolated in `Users::FromOmniauth`; existing emails are linked to the Google identity, new users are confirmed and get a generated unique username.
- Devise controllers inherit `ApplicationController` (`config.parent_controller`) so auth pages use the locale switch, Pundit, `allow_browser` and the application layout.
- Devise views use a shared two-column card partial (`devise/shared/_auth_layout.html.erb`): brand/benefits on the left, form on the right, using the existing Tailwind component classes. Devise strings come from devise-i18n.
- Registration requires accepting the terms (virtual `terms_accepted`, persisted as `terms_accepted_at`); marketing opt-in is optional.
- Pundit is included in `ApplicationController`. `Pundit::NotAuthorizedError` redirects back with a translated alert for HTML and returns 403 JSON for JSON requests.
- Stores are one-per-user seller storefronts with FriendlyId slugs and slug history. Business stores require `tax_id`. Counter/rating columns are denormalised on the store row.
- Countries are catalogue rows with ISO2 codes, VAT, currency and launch state. Names are resolved from `countries.*` translations. `Country.launched_codes` is cached and invalidated after commit.
- Regions belong to countries through the string `country_code` FK and are unique per `[country_code, code]`. Only the 52 Spanish provinces are seeded for now.
- Settings are admin-tunable JSONB values with a declared `value_type`. `Setting.get` caches typed values in `Rails.cache`; `Setting.set` infers the type and both invalidate the cache after commit.
- Seeds are split into `db/seeds/countries.rb`, `regions.rb`, `settings.rb`, `features.rb`, `categories.rb`, `attributes.rb` and `tags.rb`, loaded from `db/seeds.rb`; all are idempotent. Features start disabled, ES is the only launched country, and the confirmed admin comes from `ADMIN_PASSWORD` or `ChangeMe123!`.
- Catalogue seeds use `find_or_initialize_by` + `assign_attributes` + `save!` and local variables (no constants) so repeated loads in tests are silent. The tree has 51 categories (10 roots + 41 children), 45 attribute definitions with 428 options, and 34 tags (13 product labels + 21 seller tags). Generic option labels and tag names are translated in all six locales; brands, model names, numbers and acronyms are identical by design. Physical leaf categories automatically receive `warranty_months` and `includes_original_box`, except Games, Software and the accessory leaves other than Collectibles. Stale `CategoryAttribute` links are pruned on each run.
- Test helper injects a modern Chrome User-Agent for all integration requests (needed by `allow_browser versions: :modern`) and includes `Devise::Test::IntegrationHelpers`.
- Mobility uses the `jsonb` backend with reader/writer/query/fallbacks/presence plugins and locale accessors for all six locales; `config.i18n.fallbacks = [:en, :es]` gives the English → Spanish fallback chain. Translated catalogue columns are `jsonb NOT NULL DEFAULT '{}'`.
- `listings.searchable` is a **stored generated tsvector column** (not a trigger) so `db/schema.rb` can reproduce it. It combines title (A), `specs::text` (B) and description (C) with the `simple` config and an immutable `translate(lower(...))` accent fold; `pg_search` applies `unaccent` to the query. `pg_trgm` and `unaccent` are enabled by migration.
- Google identities are linked to existing accounts only when Google reports the email verified (`extra.raw_info.email_verified` or `info.email_verified`); otherwise the callback redirects to sign-in with a translated alert.
- Listing status is an AASM state machine on a plain string column; `Setting.get(:listings_require_approval)` decides whether submit/republish publish directly. Material edits (title/description/specs/category/photos) reset a published listing to `pending_review`; price/quantity/shipping edits do not.
- `Store#listings_count` and `Category#listings_count` are maintained by Listing `after_commit` callbacks that compare before/after `(store_id, category_id, published?)` tuples — no plain `counter_cache`.
- Category tree queries use recursive CTEs (`UNION` dedup for cycle safety); `descendant_ids` is cached with a key containing `Category.maximum(:updated_at)` and `belongs_to :parent, touch: true` propagates touches.
- `Category#effective_attribute_definitions` preloads `attribute_definition: :attribute_options` in one query.
- `Listing.with_specs` uses only jsonb containment predicates (`specs @> ?::jsonb` for the scalar and array forms of each value), so the `jsonb_path_ops` GIN index on `specs` is used; it ORs values within a key and ANDs across keys.
- Public browsing routes live inside the locale scope: categories at `/c/:slug`, listings at `/l/:slug` and search at `/search`. Category and Listing use FriendlyId `history`, so old slugs are found and 301-redirected to the current slug.
- `ListingSearch` (app/queries) owns all public listing querying and returns a result struct with Pagy records, total count, facets, applied filters and the active filter metadata. It starts from `Listing.visible`, ignores invalid numbers/params and only accepts spec keys that belong to the current category's effective filterable attributes.
- Facet and condition counts are one SQL round trip over a materialised filtered CTE using `jsonb_each`/`jsonb_array_elements_text`; counts include the attribute's own filter (zero-result options are disabled) and are cached for 5 minutes under a normalized key plus `listings/version`. `Listing` writes that version key after every commit.
- Result pages share one template. Filters submit as GET inside a Turbo frame with `data-turbo-action="advance"`; Stimulus auto-submits checkboxes and debounces text/price input (400 ms), while a `<noscript>` path keeps the form usable without JavaScript. Cards use `card` variants, eager loading for the first four, and Russian-doll fragment caching keyed by listing, locale and eager state.
- The main navigation is built from `Category.active` (one query), cached as rendered HTML per locale and mobile/desktop variant with `Category.tree_cache_version` (the maximum `updated_at`) in the key.
- Listing detail visibility is published + active store + active seller, with owners, admins and moderators able to inspect non-public listings and see a status banner. Anonymous detail responses use `fresh_when` with `[listing, locale, user id]`; anonymous category/search responses send `Cache-Control: max-age=60, public`.
- View counts increment with `update_column`, throttled by a per-listing session key. `DeliveryEstimate` counts handling days and the 2–4 day carrier window in business days, skipping weekends and starting on the next business day for weekend orders.
- SEO uses the MetaTags gem for title/description/OG/Twitter defaults and per-page overrides, hreflang alternates for all six locales plus x-default, BreadcrumbList/ItemList/Product+Offer JSON-LD, canonical URLs and `noindex,follow` on filtered or sorted result URLs. Page 2+ result URLs canonicalise to themselves.
- Active Storage variants use `:mini_magick` (ImageMagick is available; libvips is not), with `card`, `large` and `thumb` variants for listing photos.


## Schema Summary
- `users`: Devise columns plus `citext username` (unique), names, phone, `role` (0 user / 1 moderator / 2 admin), `locale`, `country_code`, ban/soft-delete timestamps, `provider`/`uid` (unique pair), marketing opt-in, `terms_accepted_at`, confirmation/lock/trackable columns.
- `stores`: unique `user_id`, `name`, unique `slug`, description, `kind` (individual/business), legal/tax/address fields, `country_code`, `verified_at`, vacation settings, `status` (active/suspended), rating/counter cache columns.
- `countries`: unique ISO2 `code`, `active`, `default_locale`, `currency`, `vat_rate`, `position`.
- `regions`: `country_code` FK to `countries.code`, `name`, `code`, `position`, unique `[country_code, code]`.
- `settings`: unique `key`, JSONB `value`, `value_type`, `group`, `description_key`.
- `categories`: self-FK `parent_id`, translated jsonb name/description/seo_title/seo_description, unique `slug` (FriendlyId from English name), `position`, `active`, `icon`, `depth`, `listings_count`. Indexes: `[parent_id, position]`, unique `slug`, `active`.
- `attribute_definitions`: unique `key`, translated `name`, `group`, `input_type` enum (single_select/multi_select/number/boolean/text), `unit`, `filterable`, `show_on_card`, `position`, `active`. Indexes: unique `key`, `[group, position]`, `active`.
- `attribute_options`: `attribute_definition_id`, `value` (unique per definition), translated `label`, `position`, `popular`, `active`.
- `category_attributes`: `[category_id, attribute_definition_id]` unique pair, `required`, `position`.
- `tags`: `kind` enum (product_label/seller_tag), translated `name`, `slug` unique per kind, `position`, `active`, `colour`. `listing_tags`: unique `[listing_id, tag_id]` plus a `tag_id` index for reverse lookups.
- `listings`: store/user/category/region FKs, title, description, unique `slug`, `condition` enum, `price_cents`, `compare_at_price_cents`, `currency`, `quantity`, `specs` jsonb, AASM `status`, moderation/lifecycle timestamps, `country_code`, `city`, `postal_code`, `shipping_mode` enum, shipping fields, `featured_until`, `views_count`, `favorites_count` and the generated `searchable` tsvector. Indexes: unique `slug`, GIN `searchable`, GIN `specs` (jsonb_path_ops), partial published indexes on `[category_id, published_at DESC]`, `published_at DESC` (named `index_listings_on_published_at_published`), `price_cents`, `region_id`, `[store_id, status]`, and a `gin_trgm_ops` GIN index on `title`.
- `listing_photos`: `listing_id`, `position`, Active Storage `image` with webp variants. `listing_moderations`: `listing_id`, `moderator_id` → users, `action` enum, `reason`. `listing_tags`: join with unique pair and a `tag_id` index.
- Supporting tables: `friendly_id_slugs`, `active_storage_blobs/attachments/variant_records`, `flipper_features`, `flipper_gates`.

## Listing state machine (AASM on `listings.status`)

```
                         submit (approval ON)          approve
   draft ────────────────────▶ pending_review ─────────────────▶ published
     ▲                              │                              │  ▲
     │                              │ reject(reason)                │  │ release
     │                              ▼                              │  │
     │                          rejected ────── submit ────────────┘  │
     │                                                  reserve        │
     │                                            published ─────────▶ reserved
     │                                                                    │
     │                                                       mark_sold  │
     ├────────────────────────── archive (any state except sold) ◀────────┤
     │                                                                    ▼
   archived ─────── republish ──────▶ pending_review (approval ON)         sold
                              └──────▶ published (approval OFF)

   submit from draft/rejected and republish from archived publish DIRECTLY
   when Setting.get(:listings_require_approval) is false.

   Material edit of a published listing (title, description, specs, category,
   or a photo add/remove) ─────▶ pending_review (only when approval is ON).
   Price / quantity / shipping edits leave the listing published.
```

## Code Map
- `config/application.rb` — locale list, default locale, fallbacks, load path, time zone.
- `config/routes.rb` — health check, OmniAuth callbacks, locale-scoped Devise/routes, admin-only Flipper UI and development letter opener.
- `config/initializers/devise.rb` — Devise setup, ApplicationController parent, Google OAuth registration, mailer sender.
- `config/initializers/flipper.rb` — Flipper ActiveRecord adapter.
- `app/controllers/application_controller.rb` — localization, Pundit, browser guard and translated `NotAuthorizedError` handling.
- `app/controllers/concerns/localization.rb` — locale detection logic validated against `I18n.available_locales`.
- `app/controllers/users/registrations_controller.rb` — permitted sign-up/account-update params.
- `app/controllers/users/omniauth_callbacks_controller.rb` — Google callback and failure handling.
- `app/controllers/pages_controller.rb` — minimal home action.
- `app/services/users/from_omniauth.rb` — create/link a user from an OmniAuth hash.
- `app/models/user.rb` — Devise identity, validations, ban/soft-delete gate, avatar validation.
- `app/models/store.rb` — seller storefront, FriendlyId, scopes and image validations.
- `app/models/country.rb` — catalogue, active scope, cached launched codes.
- `app/models/region.rb` — country-scoped administrative regions.
- `app/models/setting.rb` — typed, cached site settings.
- `app/policies/application_policy.rb` — Pundit base policy.
- `app/views/pages/home.html.erb` — translated hero.
- `app/views/layouts/application.html.erb` — `<html lang>`/theme meta, Inter font, flash-free theme script, skip link and shell partials.
- `app/views/shared/` — announcement bar, header (search, actions, account dropdown, theme toggle, locale switcher, mobile drawer), main nav, footer, flash and back-to-top partials.
- `app/views/devise/` — custom split-card auth views, shared links/errors, mailer templates.
- `app/assets/tailwind/application.css` — Tailwind import, dark variant, design tokens and component classes (`.field`, `.btn-primary`, `.btn-accent`, `.icon-button`).
- `app/javascript/controllers/{theme,drawer,dropdown,flash}_controller.js` — shell behaviour (the account and locale menus share `dropdown`).
- `config/locales/{es,en,fr,de,it,pt}.yml` — shared translation keys, countries, settings, auth, account menu, Pundit and Active Record names.
- `config/i18n-tasks.yml` — i18n-tasks configuration (dynamic keys, gem-provided Devise keys).
- `db/seeds.rb` + `db/seeds/{countries,regions,settings,features,categories,attributes,tags}.rb` — idempotent reference data (the catalogue files also build the category ↔ attribute matrix).
- `config/initializers/mobility.rb` — jsonb backend and plugin set for translated catalogue columns.
- `db/migrate/20261112110000_create_categories.rb`, `20261112110100_create_attribute_catalogue.rb`, `20261112110200_create_tags.rb`, `20261112110300_create_listings.rb` — reversible Phase 1b migrations (explicit `up`/`down` for extensions, generated column and indexes).
- `app/models/{category,attribute_definition,attribute_option,category_attribute,tag,listing_tag,listing,listing_photo,listing_moderation}.rb` — catalogue domain.
- `app/models/delivery_estimate.rb` — business-day dispatch/delivery estimate (PORO).
- `app/queries/listing_search.rb` — visible listing search, filters, sorting, Pagy pagination, facets and applied filters.
- `app/controllers/categories_controller.rb`, `app/controllers/listings_controller.rb` — category results, search results and listing detail.
- `app/controllers/concerns/listing_filters.rb` — search param whitelist and anonymous public cache headers.
- `app/helpers/{listings,pagination,seo,navigation}_helper.rb` — card/spec formatting, Pagy Tailwind nav, meta/hreflang/JSON-LD, navigation tree.
- `app/views/listings/` — shared index, card, filters, gallery, specifications, seller card and detail views.
- `app/javascript/controllers/{filters,gallery,mega_menu}_controller.js` — auto-submitting filters, photo gallery/lightbox and desktop mega-menu.
- `test/queries/listing_search_test.rb`, `test/models/delivery_estimate_test.rb` — filter/facet/pagination and delivery coverage.
- `test/controllers/{categories,listings,search,navigation}_test.rb`, `test/integration/category_page_performance_test.rb` — result pages, visibility, redirects, SEO and query-count coverage.

- `app/services/listings/moderate.rb` — admin moderation entry point (`approve!`/`reject!`) writing `ListingModeration` logs.
- `app/helpers/money_helper.rb` — locale-aware `money(cents, currency:)` using `number_to_currency`.
- `test/i18n_test.rb` — missing/unused key checks.
- `test/seeds/catalogue_seeds_test.rb` — catalogue seed counts, idempotency, six-locale coverage and leaf attribute rules.
- `test/models/{user,store,country,setting,category,listing,listing_photo,tag}_test.rb` — domain model coverage.
- `test/services/listings/moderate_test.rb`, `test/helpers/money_helper_test.rb` — service and helper coverage.
- `test/integration/{registrations,sessions,flipper_access,omniauth_callbacks}_test.rb` — auth and Flipper access flows.
- `test/controllers/{pages,layout}_controller_test.rb` — locale routing, detection and shell rendering.
- `test/fixtures/{categories,attribute_definitions,attribute_options,category_attributes,tags,listings,regions}.yml` — catalogue fixtures.
- `Procfile.dev`, `bin/dev` — development processes (web + Tailwind watch).

## Open Items
- Store dashboard, listings, sales, orders, inbox, wishlist and account-settings links are placeholders (`#`).
- The catalogue domain is browsable (category, search, filters and listing detail) but there is no admin UI for it yet.
- There is no admin UI for `Setting` yet; values are read through `Setting.get`. `Listings::Moderate` is the service the future admin panel will call.
- Buy now, add to basket, make an offer, message seller, wishlist and store links are disabled placeholders until their Phase 4+ resources exist.
- Only ES is launched and only Spanish provinces are accepted by the region filter; FR, GB, DE, IT and PT are inactive catalogue rows.
- Google OAuth credentials are not configured in development by default; the login button stays hidden until they are.
- Only `ApplicationPolicy` exists; domain policies arrive with their resources.
- The newsletter form posts nowhere, the cart badge is a static `0`, and the theme-color meta tags follow the system scheme rather than a manual toggle.
