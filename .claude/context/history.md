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
