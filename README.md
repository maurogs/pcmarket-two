# README

PCMarket is a Rails 8.1 marketplace for buying and selling PC parts. See
`.claude/context/project.md` for the architecture and current delivery state.

### Sell to us feature flag

The instant-offer flow is shipped behind Flipper `sell_to_us`. It is seeded
disabled and every public/admin route returns 404 while it is off. Enable it
from `/admin/features` (or `Flipper.enable(:sell_to_us)`) when buyback
operations are ready.

### Seeds and performance tiers

`bin/rails db:seed` seeds the games, covers and GPU/CPU tier tables.
`bin/rails pcmarket:compute_tiers` backfills `listings.gpu_tier` and
`listings.cpu_tier` from existing specs.

## API v1 (native apps)

The versioned JSON API lives at `/api/v1` and is documented in
`public/api/v1/openapi.yaml` (rendered at `/api/docs`). It is a pure
`ActionController::API` stack with token authentication, so it does not use
cookies, sessions, CSRF tokens or the browser guard used by the HTML site.

### Authentication

1. `POST /api/v1/sessions` with `email` and `password` (plus optional
   `device_name`, `platform`, `app_version`). The response contains
   `access_token`, `refresh_token`, `expires_at`, `refresh_expires_at`, the
   session and the user.
2. Send `Authorization: Bearer <access_token>` on every authenticated request.
3. Access tokens last 30 days and slide on use. Refresh tokens last 90 days and
   are single use: `POST /api/v1/session_refresh` rotates both tokens.
4. `DELETE /api/v1/sessions/current` revokes the current device.
   `GET /api/v1/sessions` lists active devices and `DELETE /api/v1/sessions/:id`
   revokes one of them.

Only SHA256 digests are stored. Registrations follow the same rules as the web
sign-up (including terms acceptance and the confirmation email). Google mobile
sign-in is `POST /api/v1/google_sessions` with a Google ID token; the token is
verified against Google's certificates and the configured client ids
(`GOOGLE_CLIENT_IDS` / `GOOGLE_CLIENT_ID`). Banned, deleted, locked and, when
`Setting.api_require_confirmation` is on, unconfirmed accounts are rejected with
a translated code. Set `api_require_confirmation` to `false` in the admin
settings if mobile clients should sign in before confirming their email.

Profile and notification preferences are available at `GET/PATCH /api/v1/me`;
account deletion is `DELETE /api/v1/me` (password or typed username
confirmation, then `Accounts::Delete`). Push device registrations use
`POST /api/v1/device_tokens` / `DELETE /api/v1/device_tokens/:id`. Sending is
still a no-op adapter (`Notifications::PushDelivery`) until APNs/FCM
credentials exist.

### Headers, locale and caching

- `Accept-Language` negotiates the locale (then the user's stored locale, then
  Spanish). Error messages and catalogue translations use it.
- `Accept: application/json` is the default and only API format.
- Collections include `X-Total-Count` and a `Link` header with
  `first`/`prev`/`next`/`last`.
- Public catalogue endpoints send `Cache-Control: public, max-age=60` for
  anonymous callers and support conditional GET (`ETag`/`Last-Modified`) on
  listing, category and storefront detail.
- Images are absolute variant URLs (`thumb`, `card`, `large`) built with
  `rails_representation_url`. Set `API_IMAGE_HOST` (and optionally the
  `API_IMAGE_PROTOCOL`) in production; it falls back to `APP_HOST` or
  `localhost:3000`.

### Pagination

Page-based collections accept `page` (1-based) and `per_page` (default 20,
maximum 50) and wrap results in `{ "data": [...], "meta": ... }`. Cursor feeds
(messages and notifications) accept `before_id` and return
`meta.next_before_id` and `meta.has_more`. Single resources use `{ "data": ... }`.
Listing search reuses the web `ListingSearch`, so filters, facets, sorting and
invalid-parameter handling are identical to the website.

### Errors

Every error uses:

```json
{ "error": { "code": "validation_failed", "message": "...", "details": { "field": ["..."] } } }
```

Codes: `unauthorized`, `forbidden`, `not_found`, `validation_failed`,
`rate_limited`, `conflict` and `feature_disabled`. AASM state-transition
failures return `409 conflict`; a disabled feature (for example offers when the
Flipper flag is off) returns `404 feature_disabled`.

### Rate limits (Rack::Attack)

- 300 requests per 5 minutes per bearer token, or per IP for anonymous calls.
- 10 sign-in attempts per minute per IP and per email.
- 5 sign-ups per hour per IP.
- HTML sign-in, sign-up and contact forms are throttled separately.

Throttled requests return `429` with `Retry-After` and the standard error
envelope. Configure allowed browser origins with `CORS_ALLOWED_ORIGINS`
(comma separated; defaults to `*` in development). CORS is applied to `/api/*`
only.

### Versioning and deprecation

The URL version is the contract (`/api/v1`). Additive changes (new optional
fields, endpoints and enum values clients can ignore) are backwards compatible
and ship within v1. Breaking changes require `/api/v2`; v1 stays available for
at least six months after v2 is announced, and deprecations are announced in
this README, in the OpenAPI description and with a `Deprecation`/`Sunset`
response header on the affected endpoints.

### Stripe on mobile

`POST /api/v1/checkouts` reuses `Checkouts::Start` and returns the
PaymentIntent `client_secret`, the publishable key, a Stripe Customer id and an
ephemeral key secret for the Stripe PaymentSheet. The customer id is stored on
`users.stripe_customer_id`. Test and key-less development installations use
`Payments::FakeGateway`, which returns deterministic fake values.

## Demo data

The development demo marketplace is built by three rake tasks. They are safe to
re-run: the seed refreshes only rows tagged `demo`, and `pcmarket:demo:reset`
removes only demo-tagged users, stores and listings (plus their activity).

```bash
bin/rails db:seed                     # countries, categories, filters, tags, games, legal pages
bin/rails pcmarket:demo:images        # download cached demo photos into tmp/demo_images
bin/rails pcmarket:demo:seed          # users, stores, ~1,500 listings, orders, reviews, chat…
```

Image fetching is resumable and cached: files and a `manifest.json` live under
`tmp/demo_images/<category>/` (gitignored), so a second run never downloads the
same photo twice. The default target is 12 photos per category; override it
with task arguments or environment variables:

```bash
bin/rake 'pcmarket:demo:images[gpus,cpus,12]'   # category slugs and per-category count
CATEGORIES=gpus PER_CATEGORY=16 bin/rails pcmarket:demo:images
```

Providers are Openverse (no key needed), Unsplash (`UNSPLASH_ACCESS_KEY`),
Pexels (`PEXELS_API_KEY`) and Pixabay (`PIXABAY_API_KEY`). Providers without a
key are skipped. Requests use timeouts and retry/backoff (including Openverse’s
anonymous rate limit); every downloaded file is resized to at most 1600 px and
stored with its author, provider, source page, licence and licence URL. The
Unsplash download endpoint is triggered when a photo is used, and
`/credits` lists every attached demo image; the footer links to it only when
demo photos exist.

When a network provider fails, both `pcmarket:demo:images` and the seed fall
back to locally generated ImageMagick placeholders (a category name on a
gradient), so seeding never depends on network access. No images are committed
to git.

Seed options:

```bash
DEMO_PASSWORD='MyDemo123!' bin/rails pcmarket:demo:seed
DEMO_SCALE=0.02 bin/rails pcmarket:demo:seed   # small dataset for CI/tests
bin/rails pcmarket:demo:reset                  # delete demo rows only
```

The seed refuses to run in production unless `DEMO=1` is set. Demo stores are
marked as payout-ready so their listings can be purchased with the fake
gateway; real Stripe keys are never touched.

Demo accounts are confirmed and all share the password from `DEMO_PASSWORD`
(default `Demo1234!`). Their emails follow
`demo-<number>-<username>@pcmarket.test`; list a few with:

```bash
bin/rails runner 'puts User.where(demo: true).limit(5).pluck(:email)'
```


## Configuration

All configuration is environment-driven; `.env.example` lists every variable
the application reads. The most important groups are:

| Variable | Purpose |
| --- | --- |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` (Stripe, Google, AWS alternatives). |
| `APP_HOST`, `APP_HOSTS` | Canonical mailer/asset host and the comma-separated Host-header allow-list. |
| `DATABASE_URL`, `APP_TEST_TWO_DATABASE_PASSWORD` | Primary PostgreSQL connection (cache/queue/cable databases are declared in `config/database.yml`). |
| `ACTIVE_RECORD_ENCRYPTION_*` | Three keys protecting buyback IBANs at rest. Required in production unless `SECRET_KEY_BASE_DUMMY=1` (asset builds). |
| `ACTIVE_STORAGE_SERVICE` | `local`, `amazon` (AWS S3) or `cloudflare` (R2). S3/R2 credentials use `AWS_*` / `R2_*`. |
| `SMTP_*` | Transactional email. When `SMTP_ADDRESS` is present, production uses SMTP and queues delivery with Solid Queue. |
| `STRIPE_*` | Live payments, Connect onboarding and webhooks. |
| `GOOGLE_CLIENT_ID(S)`, `GOOGLE_CLIENT_SECRET` | Google sign-in on web and mobile. |
| `SOLID_QUEUE_IN_PUMA` | Run the job supervisor inside Puma (`true`) or use a separate `bin/jobs` worker (`false`). |
| `ASSET_HOST`, `ACTIVE_STORAGE_HOST` | Optional CDN host for assets and the CSP image allow-list. |
| `NOINDEX=1` | Staging mode: robots.txt disallows everything. |
| `CORS_ALLOWED_ORIGINS` | Comma-separated origins allowed on `/api/*`. |
| `SITEMAP_HOST` | Public host used by the sitemap generator when `APP_HOST` is not enough. |

### Active Record encryption

Buyback IBANs are stored with Active Record encryption. In production set the
three keys through encrypted credentials under `active_record_encryption`:

```yaml
active_record_encryption:
  primary_key: "..."
  deterministic_key: "..."
  key_derivation_salt: "..."
```

Alternatively set `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`,
`ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` and
`ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`. Development and test boot with
local-only fallback values; production raises at boot when the keys are
missing. Generate values with `bin/rails db:encryption:init`. Asset builds set
`SECRET_KEY_BASE_DUMMY=1`, which skips this guard in the Docker build stage.

### Uploads and variants

`config.active_storage.variant_processor` uses libvips when `require "vips"`
succeeds and falls back to ImageMagick otherwise. The production Docker image
installs both libvips and ImageMagick. Listing photos always render through
the `thumb`/`card`/`large` variants with explicit width/height and lazy
loading.

### Sitemaps and robots

`config/sitemap.rb` generates a gzipped sitemap index plus one sitemap per
locale in `public/sitemaps`, including xhtml:link hreflang alternates for
Spanish, English, French, German, Italian, Portuguese and x-default. It covers
the home page, categories, published listings (with `lastmod`), stores, static
and legal pages and PC Finder presets. Regenerate them with:

```bash
bin/rails pcmarket:sitemaps
```

`Sitemaps::GenerateJob` repeats this daily at 03:00 through Solid Queue
(`config/recurring.yml`). `/robots.txt` is generated by `RobotsController`
(private areas and search query URLs are disallowed; `NOINDEX=1` blocks
everything).

## Deployment

1. Copy `.env.example` to `.env` and fill in the real values, or configure the
   same keys in your secret manager. Never commit `.env`.
2. Set up PostgreSQL. The application uses four logical databases (primary,
   `_cache`, `_queue`, `_cable`); create them with `bin/rails db:prepare` and
   run `bin/rails db:migrate`.
3. Build the image (`docker build -t <registry>/pcmarket .`). The build
   installs libvips, ImageMagick and libpq and precompiles assets with
   `SECRET_KEY_BASE_DUMMY=1`, so no production secret is needed at build time.
4. Deploy with Kamal using `config/deploy.yml`. Replace the placeholder hosts,
   registry and domain, then run `bin/kamal setup` / `bin/kamal deploy`. The
   `web` role serves HTTP through Thruster and the `job` role runs
   `bin/jobs`; alternatively set `SOLID_QUEUE_IN_PUMA=true` to run jobs inside
   Puma on a single host. A commented PostgreSQL accessory is included for
   single-server setups.
5. Point Stripe webhooks at `https://<host>/webhooks/stripe`, configure SMTP
   (SPF/DKIM) and, when using S3/R2, set `ACTIVE_STORAGE_SERVICE` plus the
   matching credentials. Configure `APP_HOSTS` so the Host-header allow-list
   includes the production domain.
6. Health checks: `GET /up` returns 200 only when PostgreSQL answers a query,
   otherwise 503. It is excluded from SSL redirects and Rack::Attack.

### Security headers

Production enforces HSTS (`force_ssl` + `assume_ssl`), a nonce-based Content
Security Policy (self, Google Fonts, Stripe and the configured storage host;
Redoc's CDN is only allowed on `/api/docs`), `Referrer-Policy:
strict-origin-when-cross-origin`, `Permissions-Policy` (camera, microphone,
geolocation and USB disabled), and `X-Frame-Options: DENY`. Report-only mode is
used in development, enforced in test/production. Session cookies are
HttpOnly, SameSite=Lax and Secure in production; Devise runs in paranoid mode.

### Performance checks

`bin/perf_check` simulates requests with `ActionDispatch::Integration::Session`
against the seeded development database and reports warm SQL query counts,
SQL time, render time and response size for every main page and API endpoint.
It exits non-zero when a page exceeds the launch targets (150 ms server time,
20 warm SQL queries).

```bash
bin/perf_check
bin/perf_check --only=category --dump=category
bin/perf_check --cold   # clears the cache before each measured request
```

`--cold` is diagnostic: it measures the first-render cost after a deploy or
cache expiry and will report pages above the warm targets.


## Tests

Run `bin/rails test`, `bundle exec i18n-tasks missing`, `bundle exec i18n-tasks unused`,
`bin/rubocop`, `bin/brakeman --no-pager`, `bin/bundler-audit` and `bin/importmap audit`
before shipping a change.
