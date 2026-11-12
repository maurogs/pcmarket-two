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
- Store onboarding is a singular `/store` resource (`new/create/edit/update`). Users without a store are redirected there before listing an item. `stores.region_id` links the selected Spanish province; `province` is kept in sync with the region name.
- Spanish NIF/NIE/CIF numbers are validated by `SpanishTaxIdValidator` (control letters/digits, tolerant of spaces, dots and hyphens). `Store` validates the tax ID globally and requires region/city (plus a five-digit postal code for business stores) in the `:onboarding` context.
- Business sellers' legal name, tax ID and address are rendered in the public seller card on listing pages, matching the EU DSA trader-transparency notice in the store form.
- The seller listing flow is `/sell` (`Sell::ListingsController`, RESTful index/new/create/edit/update/destroy; named `sell_listings` to avoid clashing with the public `listings` routes). Step 1 creates the draft; later steps PATCH `update` with a `step` parameter inside the `listing_wizard` Turbo frame.
- Wizard steps are `category`, `photos`, `details`, `price` and `review`. `Listing` uses those names as validation contexts; title/description/price/handling/quantity validations are skipped in earlier contexts so a draft can exist before those fields are filled. `title`, `description` and `price_cents` are nullable at database level until the matching step fills them.
- `Listings::SaveStep` persists attributes, photo uploads/removals/order and saves with the step context. `Listings::Submit` validates the `:review` context, calls the AASM `submit` event and has a TODO hook for the future moderator notification.
- Photo uploads use Active Storage direct uploads (`@rails/activestorage`), the `sortable` Stimulus controller (native HTML5 drag plus up/down buttons) and the `category_picker`, `character_counter` and `store_kind` helpers. The photo limit comes from `Setting.get(:max_images_per_listing)`, and type/size errors are translated.
- Sellers can select only seller tags (max 5) through `seller_tag_ids`; product labels remain an admin-only assignment. The offers toggle appears only when the `:offers` Flipper flag is enabled and defaults to `store.allow_offers_default`.
- `StorePolicy` lets users manage only their own store. `ListingPolicy` allows creation only for confirmed, non-banned users with a non-suspended store; edit/update/destroy are owner-only until the admin panel exists. Owners delete drafts; every other state is archived.
- The seller listings index is `GET /sell` (`Sell::ListingsController#index`). `Sell::ListingCollection` owns the tab/status mapping (active = published + reserved; pending_review, drafts, rejected, sold, archived), the single grouped status COUNT for the tab badges, the case-insensitive title filter (`ILIKE` + `sanitize_sql_like`) and Pagy pagination at 20 per page. Invalid tabs fall back to active and invalid pages clamp to the last page. The index renders a desktop table and mobile cards, with thumbnail (`:thumb`), price, status badge, views, favourites, updated date and archive/republish/delete-draft actions; checkboxes sit outside the bulk form via the HTML `form` attribute and the `bulk_select` Stimulus controller only drives select-all.
- Batch and state-transition operations are separate RESTful resources: `POST /sell/bulk-archive` (`Sell::BulkArchivesController`, `Sell::BulkArchive`) and `POST /sell/:listing_id/republish` (`Sell::ListingRepublishesController`). `Sell::BulkArchive` scopes ids to `current_user.listings`, ignores other sellers and archives only records where `may_archive?`. `ListingPolicy#republish?` mirrors `update?` (owner-only); republish uses the existing `submit`/`published` flash copy and redirects to the index.
- Deleting a draft via `Sell::ListingsController#destroy` returns to the drafts tab, and archiving any other state returns to the archived tab. Sold listings expose no archive action because AASM does not allow it.
- The header and account menu point to the real store/listing entry points. "My listings" opens `sell_listings_path`; the admin panel entry opens `admin_root_path` for admins and moderators; the store dashboard, sales, orders, inbox and wishlist remain placeholders.
- The admin area lives under the optional locale scope at `/admin`: a singular dashboard and the RESTful `listing_reviews` resource at `/admin/moderation`. Flipper's UI stays at the locale-less `/admin/flipper` mount. `Admin::BaseController` uses the dedicated admin layout, Devise authentication and a staff check that raises `ActiveRecord::RecordNotFound` for non-staff accounts, so regular users see a 404 rather than a 403.
- The admin shell has its own sidebar and top bar (listing search, six-locale switcher, back-to-site link and account menu) and deliberately omits the public header, footer and announcement bar. The sidebar lists every planned section, but only Dashboard, Moderation queue and Feature flags link anywhere; the rest render as disabled "coming soon" rows.
- `Admin::DashboardStats` caches the dashboard COUNT metrics for 60 seconds under `admin/dashboard/stats`. The dashboard table shows the ten oldest pending listings (`submitted_at ASC NULLS LAST, id ASC`).
- The moderation queue is owned by `Admin::ModerationQueue`: pending-only, category-descendant, seller-kind, photo-EXISTS and title filters, Pagy at 20 per page, the category options, the applied filters and the oldest/next/previous lookups used by the dashboard and review page. `Admin::SellerProfile` supplies account age, previous rejected moderations and the store's verified flag, batching rejection counts for the index.
- Admin policies subclass `Admin::ApplicationPolicy`: dashboard and listing moderation are available to staff, while the future user and setting screens are admin-only placeholders. The moderation controller authorises through `Admin::ListingPolicy`.
- `Listings::Moderate` performs the pending check, AASM transition and moderation log inside `listing.with_lock`; a second moderator receives `nil` with no duplicate log or email. Emails are enqueued only after the lock transaction returns successfully.
- `ListingModeration::REJECTION_REASONS` lists the eight predefined reasons. `ListingModeration.compose_reason` translates the selected code in the seller's locale and joins it to the optional note with an em dash; the combined text is stored on both `listings.rejection_reason` and `listing_moderations.reason`.
- `ListingMailer#approved`/`#rejected` render HTML and text in the seller's locale through `I18n.with_locale`, pass the locale explicitly to listing/edit URLs and use the inline-styled `listing_mailer` layout. The dashboard/review UI uses the `moderation_shortcuts` Stimulus controller (A, R, J/K) and ignores keys while typing.


## Schema Summary
- `users`: Devise columns plus `citext username` (unique), names, phone, `role` (0 user / 1 moderator / 2 admin), `locale`, `country_code`, ban/soft-delete timestamps, `provider`/`uid` (unique pair), marketing opt-in, `terms_accepted_at`, confirmation/lock/trackable columns.
- `stores`: unique `user_id`, `name`, unique `slug`, description, `kind` (individual/business), `region_id` FK (selected province), legal/tax/address fields, `country_code`, `verified_at`, vacation settings, `status` (active/suspended), rating/counter cache columns.
- `countries`: unique ISO2 `code`, `active`, `default_locale`, `currency`, `vat_rate`, `position`.
- `regions`: `country_code` FK to `countries.code`, `name`, `code`, `position`, unique `[country_code, code]`.
- `settings`: unique `key`, JSONB `value`, `value_type`, `group`, `description_key`.
- `categories`: self-FK `parent_id`, translated jsonb name/description/seo_title/seo_description, unique `slug` (FriendlyId from English name), `position`, `active`, `icon`, `depth`, `listings_count`. Indexes: `[parent_id, position]`, unique `slug`, `active`.
- `attribute_definitions`: unique `key`, translated `name`, `group`, `input_type` enum (single_select/multi_select/number/boolean/text), `unit`, `filterable`, `show_on_card`, `position`, `active`. Indexes: unique `key`, `[group, position]`, `active`.
- `attribute_options`: `attribute_definition_id`, `value` (unique per definition), translated `label`, `position`, `popular`, `active`.
- `category_attributes`: `[category_id, attribute_definition_id]` unique pair, `required`, `position`.
- `tags`: `kind` enum (product_label/seller_tag), translated `name`, `slug` unique per kind, `position`, `active`, `colour`. `listing_tags`: unique `[listing_id, tag_id]` plus a `tag_id` index for reverse lookups.
- `listings`: store/user/category/region FKs, nullable `title`/`description`/`price_cents` while the wizard draft is incomplete, unique `slug`, `condition` enum, `compare_at_price_cents`, `currency`, `quantity`, `specs` jsonb, AASM `status`, moderation/lifecycle timestamps, `country_code`, `city`, `postal_code`, `shipping_mode` enum, shipping fields, `featured_until`, `views_count`, `favorites_count` and the generated `searchable` tsvector. Indexes: unique `slug`, GIN `searchable`, GIN `specs` (jsonb_path_ops), partial published indexes on `[category_id, published_at DESC]`, `published_at DESC` (named `index_listings_on_published_at_published`), `price_cents`, `region_id`, `[store_id, status]`, and a `gin_trgm_ops` GIN index on `title`.
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
- `app/services/listings/save_step.rb` — wizard step persistence (attributes, photo uploads/removals/order, step validation context).
- `app/services/listings/submit.rb` — review validation + AASM `submit` event, with the moderator notification TODO.
- `app/validators/spanish_tax_id_validator.rb` — NIF/NIE/CIF control-character validation.
- `app/controllers/stores_controller.rb` — singular store onboarding and settings (`:onboarding` validation context).
- `app/controllers/sell/listings_controller.rb` — seller listings index, five-step listing wizard, submit and draft/archive deletion.
- `app/queries/sell/listing_collection.rb` — seller listing tabs, grouped tab counts, title filter and Pagy pagination.
- `app/services/sell/bulk_archive.rb`, `app/controllers/sell/bulk_archives_controller.rb` — owner-scoped batch archive (`POST /sell/bulk-archive`).
- `app/controllers/sell/listing_republishes_controller.rb` — owner-only republish transition (`POST /sell/:listing_id/republish`).
- `app/controllers/admin/{base,dashboard,listing_reviews}_controller.rb` — staff-only shell, dashboard and the moderation queue/preview/decision resource.
- `app/queries/admin/{dashboard_stats,moderation_queue,seller_profile}.rb` — cached KPI counts and dashboard rows, the filtered pending queue with pagination/neighbours, and seller-level moderation facts.
- `app/policies/admin/{application,dashboard,listing,user,setting}_policy.rb` — staff/admin policy hierarchy.
- `app/helpers/admin_helper.rb` — sidebar items (real links vs disabled placeholders), KPI/reason/action labels and nav classes.
- `app/views/layouts/admin.html.erb`, `app/views/admin/shared/{_sidebar,_topbar}.html.erb` — noindex admin shell with drawer sidebar, search, locale switcher and account menu.
- `app/views/admin/dashboard/show.html.erb`, `app/views/admin/listing_reviews/{index,show,_queue_row,_queue_card,_thumbnail}.html.erb` — KPI cards, oldest pending table, filtered queue and review page.
- `app/mailers/listing_mailer.rb`, `app/views/layouts/listing_mailer.{html,text}.erb`, `app/views/listing_mailer/{approved,rejected}.{html,text}.erb` — locale-aware approval/rejection emails with an inline-styled branded layout.
- `test/mailers/previews/listing_mailer_preview.rb` — Letter Opener previews for the moderation emails.
- `app/javascript/controllers/moderation_shortcuts_controller.js` — A/R/J/K keyboard shortcuts, disabled while typing.
- `app/policies/store_policy.rb`, `app/policies/listing_policy.rb` — own-store and owner/create eligibility rules.
- `app/helpers/sell_helper.rb` — wizard progress labels, condition copy and review field labels.
- `app/views/stores/` — onboarding/settings form with kind toggle and business legal fields.
- `app/views/sell/listings/` — seller index (tabs, table, mobile cards, bulk bar), wizard shell, progress and the category/photos/details/price/review step partials.
- `app/views/shared/_form_errors.html.erb` — shared validation summary.
- `app/javascript/controllers/{wizard,sortable,category_picker,character_counter,store_kind,bulk_select}_controller.js` — wizard progress, photo reordering, category search, counters, business-field toggling and seller bulk selection.
- `test/validators/spanish_tax_id_validator_test.rb`, `test/policies/{store,listing}_policy_test.rb`, `test/models/listing_wizard_validation_test.rb` — validator, policy and step-context coverage.
- `test/integration/{store_onboarding,sell_listings_wizard,sell_listings_index}_test.rb` — onboarding, wizard happy paths, approval-off, photo limit, compare-at, review, seller tabs/filter/bulk/republish and delete/archive coverage.
- `app/helpers/money_helper.rb` — locale-aware `money(cents, currency:)` using `number_to_currency`.
- `test/i18n_test.rb` — missing/unused key checks.
- `test/seeds/catalogue_seeds_test.rb` — catalogue seed counts, idempotency, six-locale coverage and leaf attribute rules.
- `test/models/{user,store,country,setting,category,listing,listing_photo,tag}_test.rb` — domain model coverage.
- `test/services/listings/moderate_test.rb`, `test/helpers/money_helper_test.rb` — service and helper coverage.
- `test/integration/{registrations,sessions,flipper_access,omniauth_callbacks}_test.rb` — auth and Flipper access flows.
- `test/integration/{admin_access,admin_dashboard,admin_moderation}_test.rb` — staff 404/redirect rules, KPI values, queue filters, review content, approve/reject, concurrency and emails.
- `test/policies/admin/listing_policy_test.rb`, `test/mailers/listing_mailer_test.rb` — staff policy rules and locale-aware moderation emails; `test/mailers/previews/` holds the mailer preview.
- `test/services/listings/moderate_test.rb` — moderation transitions, emails and the double-moderation guard.
- `test/controllers/{pages,layout}_controller_test.rb` — locale routing, detection and shell rendering.
- `test/fixtures/{categories,attribute_definitions,attribute_options,category_attributes,tags,listings,regions}.yml` — catalogue fixtures.
- `Procfile.dev`, `bin/dev` — development processes (web + Tailwind watch).

## Open Items
- The seller listings index is in place; store dashboard, sales, orders, inbox, wishlist, public store and account-settings links remain placeholders (`#`).
- The admin area now has a dashboard and a moderation queue. Admin screens for listings, users, stores, orders, categories, filters/attributes, tags, countries, settings, legal pages and reports are still placeholders (disabled “coming soon” sidebar rows).
- The catalogue domain is fully browsable and the moderation review page reuses the public buyer preview, but the catalogue CRUD screens (categories, attributes, tags, countries) are not built.
- `Setting` values are still read and written through `Setting.get`/`Setting.set`; the admin settings screen is a placeholder.
- `Listings::Submit` still has a TODO to enqueue the moderator notification on submission. Seller approval/rejection emails now exist through `ListingMailer`.
- Buy now, add to basket, make an offer, message seller, wishlist and store links are disabled placeholders until their Phase 4+ resources exist.
- Only ES is launched and only Spanish provinces are accepted by the region filter; FR, GB, DE, IT and PT are inactive catalogue rows.
- Google OAuth credentials are not configured in development by default; the login button stays hidden until they are.
- The newsletter form posts nowhere, the cart badge is a static `0`, and the theme-color meta tags follow the system scheme rather than a manual toggle.
- Editing a published listing relies on the existing material-edit rule. Sold listings cannot be archived by the AASM state machine, so the seller index shows them without an archive action until sales exist.
