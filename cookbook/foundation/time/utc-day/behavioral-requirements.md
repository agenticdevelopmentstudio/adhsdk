
- **day-string-from-date**: `string(from:)` MUST return the `yyyy-MM-dd` calendar day in UTC that contains the given `Date`.
- **utc-pinned**: `string(from:)` MUST NOT depend on the host's locale or time zone; the day is computed with the fixed `UTC` time zone.
- **matches-wire-prefix**: The output of `string(from:)` MUST equal the first 10 characters of the instant's UTC ISO-8601 form.
- **day-after**: `dayAfter(_:)` MUST return the `yyyy-MM-dd` UTC day following a `yyyy-MM-dd` UTC string, carrying across month, year and leap-day boundaries.
- **day-after-parses-midnight**: `dayAfter(_:)` MUST read its input as the UTC midnight that starts that day.
- **day-after-unparseable**: `dayAfter(_:)` MUST return its input unchanged when that instant cannot be parsed.
- **day-after-out-of-range**: `dayAfter(_:)` MUST return its input unchanged when a field is out of range, for example month 13 (`2026-13-01`).
- **no-throw**: Both functions MUST NOT throw; failure is expressed only by `dayAfter(_:)` returning its input.
- **stateless**: Both functions MUST be pure apart from reading their arguments; the type holds no mutable state.

