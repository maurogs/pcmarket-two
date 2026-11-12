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
- Spanish is the default locale; English is the fallback (`config.i18n.fallbacks = [:en]`).
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
- Seeds are split into `db/seeds/countries.rb`, `regions.rb`, `settings.rb` and `features.rb`, loaded from `db/seeds.rb`; all are idempotent. Features start disabled, ES is the only launched country, and the confirmed admin comes from `ADMIN_PASSWORD` or `ChangeMe123!`.
- Test helper injects a modern Chrome User-Agent for all integration requests (needed by `allow_browser versions: :modern`) and includes `Devise::Test::IntegrationHelpers`.

## Schema Summary
- `users`: Devise columns plus `citext username` (unique), names, phone, `role` (0 user / 1 moderator / 2 admin), `locale`, `country_code`, ban/soft-delete timestamps, `provider`/`uid` (unique pair), marketing opt-in, `terms_accepted_at`, confirmation/lock/trackable columns.
- `stores`: unique `user_id`, `name`, unique `slug`, description, `kind` (individual/business), legal/tax/address fields, `country_code`, `verified_at`, vacation settings, `status` (active/suspended), rating/counter cache columns.
- `countries`: unique ISO2 `code`, `active`, `default_locale`, `currency`, `vat_rate`, `position`.
- `regions`: `country_code` FK to `countries.code`, `name`, `code`, `position`, unique `[country_code, code]`.
- `settings`: unique `key`, JSONB `value`, `value_type`, `group`, `description_key`.
- Supporting tables: `friendly_id_slugs`, `active_storage_blobs/attachments/variant_records`, `flipper_features`, `flipper_gates`.

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
- `db/seeds.rb` + `db/seeds/{countries,regions,settings,features}.rb` — idempotent reference data.
- `test/i18n_test.rb` — missing/unused key checks.
- `test/models/{user,store,country,setting}_test.rb` — domain model coverage.
- `test/integration/{registrations,sessions,flipper_access}_test.rb` — auth and Flipper access flows.
- `test/controllers/{pages,layout}_controller_test.rb` — locale routing, detection and shell rendering.
- `Procfile.dev`, `bin/dev` — development processes (web + Tailwind watch).

## Open Items
- Store dashboard, listings, sales, orders, inbox, wishlist and account-settings links are placeholders (`#`).
- Only ES is launched and only Spanish regions are seeded; FR, GB, DE, IT and PT are inactive catalogue rows.
- Google OAuth credentials are not configured in development by default; the login button stays hidden until they are.
- Only `ApplicationPolicy` exists; domain policies arrive with their resources.
- There is no admin UI for `Setting` yet; values are read through `Setting.get`.
- The search form (GET `root_path` with `q`) has no results action yet.
- The newsletter form posts nowhere, the cart badge is a static `0`, and the theme-color meta tags follow the system scheme rather than a manual toggle.
