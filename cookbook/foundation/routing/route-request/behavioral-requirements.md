
### Shape

- **fields**: A `RouteRequest` MUST carry `method`, `path`, `queryValues` (`[String: [String]]`), `headers` (`[String: String]`) and `body` (`Data`) exactly as given to `init`.
- **init-defaults**: `init` MUST default `queryValues` to an empty dictionary, `headers` to an empty dictionary and `body` to empty `Data`.
- **value-semantics**: A `RouteRequest` MUST be `Sendable` and `Equatable`; two requests are equal when every field is equal.
- **path-components**: `pathComponents` MUST split `path` on `/` and drop empty segments, so `//sessions//abc/` yields `["sessions", "abc"]` and `/` yields an empty list.

### Query accessors

- **query-last-value**: `query(key)` MUST return the last value of `key`, or `nil` when the key is absent.
- **query-all-wire-order**: `queryAll(key)` MUST return every value of `key` in wire order, or an empty list when the key is absent.
- **query-int-default**: `queryInt(key, default:)` MUST return the last value of `key` parsed as an `Int`, and MUST return the default (0 when none is given) when the key is absent or its value is not an integer. An integer is an optional single leading `+` or `-` followed by one or more ASCII decimal digits, with no whitespace, no other character and a value that fits the platform's signed 64-bit `Int`, which is the grammar of Swift's `Int(String)`; a value outside it (`" 5"`, `"5 "`, `"1e3"`, `""`, an overflowing digit string) takes the default.

### Paging bounds

- **limit-default**: `boundedLimit(default:max:)` MUST return the default when `limit` is absent or unparseable, and MUST bound that default to `1...max` as well, so a default above `max` returns `max`.
- **limit-in-range**: `boundedLimit(default:max:)` MUST return the requested `limit` when it is within `1...max`.
- **limit-capped**: `boundedLimit(default:max:)` MUST return `max` when `limit` exceeds it.
- **limit-floored-at-one**: `boundedLimit(default:max:)` MUST return 1 when `limit` is zero or negative, and MUST NOT pass a negative value through, because SQLite reads a negative `LIMIT` as no limit.
- **limit-clamp-is-silent**: A `limit` outside `1...max` MUST be clamped silently and MUST NOT produce an error; the source records this as deliberate for read-only paging parameters on a localhost API.
- **ceiling-below-one**: NEEDS REVIEW: Not implemented in source. Behavior undefined. The doc comment promises a result always within `1...max`, but a `max` below 1 returns `max` itself (the computation is the minimum of the floored value and the ceiling), so the promise fails and nothing rejects or documents a ceiling below 1. Evidence that would settle it: a statement of whether callers may pass such a ceiling, or a precondition on the parameter.
- **offset-default**: `boundedOffset()` MUST return 0 when `offset` is absent or unparseable.
- **offset-in-range**: `boundedOffset()` MUST return the requested `offset` when it is zero or greater.
- **offset-floored-at-zero**: `boundedOffset()` MUST return 0 when `offset` is negative.

### Timestamps

- **timestamp-absent-is-unbounded**: `validatedTimestamp(name)` MUST return `.success(nil)` when the parameter is absent or its last value is empty; an unbounded window is the documented default, not a bad request.
- **timestamp-validated**: `validatedTimestamp(name)` MUST return `.failure(InvalidTimestamp)` when the last value is non-empty and is not an ISO-8601 instant accepted by `TimestampParsing.parseISO8601`, and MUST NOT clamp, guess or fall back to a default.
- **timestamp-normalized**: A valid value MUST be re-emitted in canonical form: an internet date-time in UTC with fractional seconds (`2026-01-31T00:00:00Z` becomes `2026-01-31T00:00:00.000Z`), so string comparison agrees with the instant it names.
- **timestamp-rebased-to-utc**: A valid value with a zone offset MUST be rebased to UTC (`2026-01-31T02:00:00+02:00` becomes `2026-01-31T00:00:00.000Z`).
- **timestamp-fraction-preserved**: A valid value with fractional seconds MUST keep them (`2026-01-31T00:00:00.500Z` is unchanged).
- **normalized-timestamp-static**: `RouteRequest.normalizedTimestamp(raw, name:)` MUST apply the same parse-and-canonicalize step to a given string, and MUST return `.failure` for a string `TimestampParsing.parseISO8601` rejects.
- **failure-message-format**: A rejection MUST carry exactly the message ``"`{name}` must be an ISO8601 timestamp (e.g. 2026-01-31T00:00:00Z); got \"{raw}\""``, where `{name}` is the parameter name and `{raw}` is the rejected value, unescaped, so a caller knows which of several bounds was wrong.
- **activity-since-absent-is-empty**: `RouteRequest.activitySince(raw)` MUST return `.success("")` when `raw` is `nil` or empty.
- **activity-since-whole-seconds**: `RouteRequest.activitySince(raw)` MUST return the instant in the whole-second `UTCTimestamp` form with fractions truncated (`2026-10-03T11:00:00.500Z` becomes `2026-10-03T11:00:00Z`), because the fractional form would compare wrongly byte for byte against whole-second columns.
- **activity-since-name**: `RouteRequest.activitySince(raw)` MUST name the parameter `since` in a rejection and MUST take only the text, not a parameter name.
- **same-validator-as-core**: Both timestamp paths MUST accept exactly the strings `TimestampParsing.parseISO8601` accepts, so a CLI that checks a flag and the daemon that reads it never disagree. That validator refuses the SQLite date-time shape (`2026-10-01 00:00:00`), a bare date and a bare year.
- **pure-and-synchronous**: Every accessor and validator MUST depend only on the request and its arguments, MUST NOT perform I/O, and MUST NOT mutate the request.

