# Project Context

## Overview
PCMarket is a Rails 8.1 marketplace for buying and selling PC parts. This document tracks architectural decisions, the current code map and open items.

## Stack
- Ruby 4.0.9, Rails 8.1.4, PostgreSQL
- Propshaft asset pipeline, importmap, Hotwire
- Tailwind CSS via `tailwindcss-rails` (source in `app/assets/tailwind/application.css`, compiled to `app/assets/builds/tailwind.css`)
- I18n with six locales: es (default), en, fr, de, it, pt
- Devise, Pundit, Pagy, pg_search, FriendlyId, MetaTags, SitemapGenerator, Flipper, Mobility, AASM, Stripe, Rack::Attack, ActiveStorageValidations
- i18n-tasks and Faker in development/test

## Decisions
- Spanish is the default locale; English is the fallback (`config.i18n.fallbacks = [:en]`).
- Time zone is `Madrid`.
- English copy uses British spelling (en-GB): colour, favourites, basket.
- All user-facing strings live in `config/locales/*.yml` with an identical nested key structure rooted at each language code.
- Locale is detected in `app/controllers/concerns/localization.rb` with this priority: `params[:locale]`, `cookies[:locale]`, `Accept-Language`, `I18n.default_locale`.
- The chosen locale is persisted in `cookies[:locale]` for one year.
- HTML routes live under an optional locale scope `scope "(:locale)", locale: /es|en|fr|de|it|pt/`; the health check stays outside it.
- `locale.names.*` keys are referenced dynamically by the locale switcher and are explicitly ignored by i18n-tasks.
- Tailwind is linked through `stylesheet_link_tag :app`, which includes all CSS under `app/assets` (application.css and the compiled tailwind.css).
- The Tailwind watcher runs as `tailwindcss:watch[always]` in `Procfile.dev` so it stays alive when stdin is closed (non-interactive shells/CI).
- Flipper uses the ActiveRecord adapter; its `flipper_features` and `flipper_gates` tables are created by the generated migration `db/migrate/20261112085830_create_flipper_tables.rb`.

## Code Map
- `config/application.rb` — locale list, default locale, fallbacks, load path, time zone.
- `config/routes.rb` — health check plus locale-scoped root route.
- `app/controllers/application_controller.rb` — includes `Localization`, registers `switch_locale`, sets `default_url_options`.
- `app/controllers/concerns/localization.rb` — supported locales constant and detection logic.
- `app/controllers/pages_controller.rb` — minimal home action.
- `app/views/pages/home.html.erb` — renders the tagline.
- `app/views/layouts/application.html.erb` — translated nav, locale switcher and footer.
- `config/locales/{es,en,fr,de,it,pt}.yml` — shared translation keys.
- `config/i18n-tasks.yml` — i18n-tasks configuration.
- `test/i18n_test.rb` — missing/unused key checks.
- `test/controllers/pages_controller_test.rb` — locale routing and detection tests.
- `Procfile.dev`, `bin/dev` — development processes (web + Tailwind watch).
- `db/migrate/20261112085830_create_flipper_tables.rb` — Flipper feature and gate tables.

## Open Items
- Devise, Pundit and other domain gems are installed but not configured yet.
- No marketplace models or migrations exist yet; only the Flipper tables migration is present.
- Locale switcher links are functional, but the remaining nav links are placeholders (`#`).
- The search form has no action yet.
