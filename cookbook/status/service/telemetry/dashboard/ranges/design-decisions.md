
**Decision**: The 24h range has 25 buckets, not 24.
**Rationale**: The window holds 24 full hours plus the current, partial hour. Anchoring the first bucket to the hour boundary 24 hours before the current hour start keeps every bucket on a whole hour, so provider data grouped by hour lines up exactly.
**Approved**: pending

**Decision**: Day ranges are UTC days including today, so the last bucket is a partial day.
**Rationale**: The source comment says "that many UTC days including today". A fixed UTC boundary gives the same buckets for every viewer and matches providers that group by UTC day; a rolling 7 or 30 times 24 hours would not align to those groupings.
**Approved**: pending

**Decision**: Alignment matches bucket starts exactly and drops everything else, instead of rounding timestamps into the containing bucket.
**Rationale**: The source comment says "Anything off the axis is dropped". The providers are queried with the same grouping as the buckets, so exact matching is enough, and it keeps stray out-of-window points from inflating the edge buckets.
**Approved**: pending

**Decision**: Quiet buckets hold zero instead of being absent.
**Rationale**: The module's header comment states it: "a quiet hour reads as a zero rather than a gap", so that PostHog's and Vercel's series can share one chart.
**Approved**: pending

**Decision**: Timestamps are normalised through `new Date(ms).toISOString()` before lookup, and both a string and a number are accepted.
**Rationale**: Providers spell the same instant differently (`...00Z` against `...00.000Z`). The test "zero-fills, tolerates either timestamp spelling, and sums repeats" pins this.
**Approved**: pending

**Decision**: The module does not validate its range argument or the clock reading.
**Rationale**: The function is typed to `AnalyticsRange`, and validation of outside input happens at the edge, in the dashboard route and the report parameter parser, both of which check against `ANALYTICS_RANGES`.
**Approved**: pending

