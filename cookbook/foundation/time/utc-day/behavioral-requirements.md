
- **day-string-from-date**: `string(from:)` MUST return the `yyyy-MM-dd` calendar day in UTC that contains the given `Date`.
- **utc-pinned**: `string(from:)` MUST NOT depend on the host's locale or time zone; the day is computed with the fixed `UTC` time zone.
- **delegates-to-utc-timestamp**: Day formatting MUST be delegated to `UTCTimestamp.day(of:in:)` and `UTCTimestamp.day(epochSeconds:in:)` with the UTC zone, so the output matches the day prefix of a wire instant.
- **day-after**: `dayAfter(_:)` MUST return the `yyyy-MM-dd` UTC day following a `yyyy-MM-dd` UTC string, carrying across month, year and leap-day boundaries.
- **day-after-fixed-length**: `dayAfter(_:)` MUST advance by exactly 86,400 seconds, because UTC has no daylight-saving transitions.
- **day-after-parses-midnight**: `dayAfter(_:)` MUST read its input as the instant `<day>T00:00:00Z` through `UTCTimestamp.epochSeconds(_:)`.
- **day-after-unparseable**: `dayAfter(_:)` MUST return its input unchanged when that instant cannot be parsed. The doc comment calls this defensive, since callers only pass strings this type produced.
- **no-throw**: Both functions MUST NOT throw; failure is expressed only by `dayAfter(_:)` returning its input.
- **stateless**: Both functions MUST be pure apart from reading their arguments; the type holds no mutable state.

