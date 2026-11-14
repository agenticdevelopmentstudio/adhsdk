
`RouteRequest` has one user-facing string, the timestamp rejection message, which is hardcoded English and is not localized. It is an API error text read by clients, not a UI string.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline literal) | `` `{name}` must be an ISO8601 timestamp (e.g. 2026-01-31T00:00:00Z); got "{raw}" `` | Message of `InvalidTimestamp` from `validatedTimestamp`, `normalizedTimestamp` and `activitySince`. |

