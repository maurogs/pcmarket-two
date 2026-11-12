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

## Tests

Run `bin/rails test`, `bundle exec i18n-tasks missing`, `bundle exec i18n-tasks unused`
and `bin/rubocop` before shipping a change.
