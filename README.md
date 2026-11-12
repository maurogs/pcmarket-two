# README

PCMarket is a Rails 8.1 marketplace for buying and selling PC parts. See
`.claude/context/project.md` for the architecture and current delivery state.

## Configuration

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
missing. Generate values with `bin/rails db:encryption:init`.

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

## Tests

Run `bin/rails test`, `bundle exec i18n-tasks missing`, `bundle exec i18n-tasks unused`,
`bin/rubocop` and `bin/brakeman --no-pager` before shipping a change.
