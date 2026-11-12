# Change History

## 2026-11-12 — Phase 0a: foundations, Tailwind and I18n
- Added the marketplace gem set (Devise, Pundit, Pagy, pg_search, FriendlyId, MetaTags, SitemapGenerator, Flipper, Mobility, AASM, Stripe, Rack::Attack, ActiveStorageValidations, Rails I18n, Tailwind) plus Faker and i18n-tasks in development/test.
- Installed Tailwind CSS with `tailwindcss:install`: added `app/assets/tailwind/application.css`, `app/assets/builds/`, `Procfile.dev` and a foreman-based `bin/dev`.
- Configured six locales (es default, en fallback) and Madrid time zone in `config/application.rb`.
- Replaced the default `config/locales/en.yml` with complete es/en/fr/de/it/pt files sharing an identical key structure and natural translations.
- Added locale-scoped routing with a minimal `PagesController#home` and tagline view.
- Added `Localization` concern for param/cookie/Accept-Language detection and cookie persistence, wired into `ApplicationController`.
- Rebuilt the application layout with translated navigation, locale switcher and footer.
- Added i18n-tasks configuration and minitest checks for missing and unused keys.
- Added controller tests for locale routing and Accept-Language detection.
- Why: establish the internationalised, styled foundation required by later marketplace phases.
- Files: `Gemfile`, `Gemfile.lock`, `.gitignore`, `Procfile.dev`, `bin/dev`, `config/application.rb`, `config/routes.rb`, `config/i18n-tasks.yml`, `config/locales/*.yml`, `app/controllers/application_controller.rb`, `app/controllers/concerns/localization.rb`, `app/controllers/pages_controller.rb`, `app/views/layouts/application.html.erb`, `app/views/pages/home.html.erb`, `app/assets/tailwind/application.css`, `test/i18n_test.rb`, `test/controllers/pages_controller_test.rb`.

## 2026-11-12 — Tailwind watcher resilience
- Changed the `css` process in `Procfile.dev` to `bin/rails tailwindcss:watch[always]` so Tailwind v4 keeps watching when stdin is closed (non-interactive shells/CI) instead of exiting and causing foreman to stop the web process.
- Verified with `foreman check` and by running the watcher with `/dev/null` stdin under a 5-second alarm.
- Files: `Procfile.dev`, `.claude/context/project.md`.

## 2026-11-12 — Flipper ActiveRecord tables
- Generated and ran `db/migrate/20261112085830_create_flipper_tables.rb` (explicit `up`/`down`), creating `flipper_features` and `flipper_gates`.
- Why: Flipper's Memoizer middleware queries these tables on every request in development; without them `bin/dev` returned 500 on every page.
- Verified rollback/re-migrate, a live `PORT=3013 bin/dev` with GET `/fr` and GET `/` returning 200 and the correct taglines, and the full test suite.
- Files: `db/migrate/20261112085830_create_flipper_tables.rb`, `db/schema.rb` (generated), `.claude/context/project.md`.

## 2026-11-12 — Phase 0b: app shell and design system
- Replaced `Localization::SUPPORTED_LOCALES` with `I18n.available_locales` for locale validation.
- Added Tailwind v4 design tokens in `@theme` (primary 50–900 indigo/violet, coral accent, semantic surface/canvas/content/muted/border, success/warning/danger, radius and Inter font) plus a class-based dark variant; `.dark` overrides the semantic variables and an inline head script applies the stored/system theme before paint.
- Split the layout into `app/views/shared/` partials: announcement bar, header (logo, search, CTAs, wishlist/notifications/cart/account icons, theme toggle, locale dropdown), category nav, footer (newsletter, three link columns, legal row, socials), flash and back-to-top. Added a mobile off-canvas drawer with search and nav.
- Added Stimulus `theme`, `drawer`, `dropdown` and `flash` controllers. Added skip link, aria-labels, focus rings, viewport and light/dark theme-color meta.
- Added the translated home hero and all new copy in the six locales; i18n-tasks ignores the dynamic `nav.categories.*` keys.
- Added `test/controllers/layout_test.rb` for shell rendering, `<html lang="en">` and locale-switcher links.
- Verified `bin/rails tailwindcss:build`, `bin/rails test` (8 runs, 36 assertions, 0 failures) and rubocop on the changed Ruby files.
- Files: `app/controllers/concerns/localization.rb`, `app/assets/tailwind/application.css`, `app/views/layouts/application.html.erb`, `app/views/pages/home.html.erb`, `app/views/shared/*.erb`, `app/javascript/controllers/{theme,drawer,dropdown,flash}_controller.js`, `config/locales/*.yml`, `config/i18n-tasks.yml`, `test/controllers/layout_test.rb`, `.claude/context/project.md`.

## 2026-11-12 — Phase 1a: accounts, stores, countries and site settings
- Installed Devise, Pundit, FriendlyId and Active Storage; added letter_opener_web for development mail previews at `/letter_opener`.
- Built the `users` table and model with citext username, names, phone, role enum, locale/country defaults, ban/soft-delete timestamps, Google identity columns, marketing consent, `terms_accepted_at`, confirmation/lock/trackable columns and an avatar attachment (png/jpeg/webp, 5 MB).
- Added registration consent requirements, translated ban/deletion failures, a Google OAuth callback controller and the `Users::FromOmniauth` service. Google credentials are optional; the provider, routes and button only appear when configured.
- Moved Devise routes inside the optional locale scope while keeping OmniAuth callbacks outside it; Devise controllers now inherit `ApplicationController` so auth pages get locale switching and the browser guard.
- Restyled sign in, sign up, password reset/forgot, confirmation and unlock views as a shared split card using the existing Tailwind tokens, and replaced the generated `devise.en.yml` with devise-i18n plus our own keys.
- Included Pundit and added translated HTML/JSON handling for `NotAuthorizedError`.
- Added `Store` (one per user, FriendlyId slug history, business tax-id rule, scopes, image attachments and counter caches), `Country` (ISO2 catalogue, cached launched codes), `Region` (string country FK) and `Setting` (typed JSONB, cached get/set).
- Added idempotent seed files for six countries (ES active, GBP for GB), 52 Spanish provinces, 11 settings, six disabled Flipper features and a confirmed admin. Configured Flipper's ActiveRecord adapter and mounted its admin-only UI.
- Replaced the header account icon with a signed-in/signed-out dropdown covering orders, inbox, wishlist, account settings, store links, admin panel and logout.
- Added model and integration tests, plus a global modern Chrome User-Agent and Devise helpers in `test_helper`.
- Verified `bin/rails db:migrate`, two consecutive `bin/rails db:seed` runs, `bin/rails tailwindcss:build`, `bin/rails test` (43 runs, 134 assertions, 0 failures), `bundle exec i18n-tasks missing` and `unused` (both clean), and rendered all five auth pages in every locale.
- Files: `Gemfile`, `Gemfile.lock`, `config/routes.rb`, `config/initializers/devise.rb`, `config/initializers/flipper.rb`, `config/environments/development.rb`, `config/i18n-tasks.yml`, `config/locales/{es,en,fr,de,it,pt}.yml`, `app/models/{user,store,country,region,setting}.rb`, `app/services/users/from_omniauth.rb`, `app/controllers/application_controller.rb`, `app/controllers/users/*`, `app/views/devise/**/*`, `app/views/shared/_header.html.erb`, `db/migrate/*`, `db/seeds.rb`, `db/seeds/*.rb`, `db/schema.rb` (generated), `test/fixtures/{users,stores,countries}.yml`, `test/models/*`, `test/integration/*`, `test/test_helper.rb`, `.claude/context/project.md`.
