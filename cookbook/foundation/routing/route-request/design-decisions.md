
**Decision**: `boundedLimit` clamps in both directions instead of using `min(limit, max)`.
**Rationale**: The source records that `min(limit, max)` is not a clamp: SQLite reads a negative `LIMIT` as no limit, so `?limit=-1` turned a bounded page into the whole table (500 rows against 2,300 measured live), and four handlers had no bound at all.
**Approved**: pending

**Decision**: Out-of-range paging values are clamped silently, while a malformed timestamp is a failure.
**Rationale**: The source says paging parameters are read-only and on a localhost API, so a caller asking for more than the ceiling wants as much as it can get; a malformed timestamp has no safe interpretation, because a lexicographic comparison would return the wrong rows with HTTP 200.
**Approved**: pending

**Decision**: Timestamps are normalized to UTC with fractional seconds before they reach a query.
**Rationale**: The source records that stored timestamps carry fractions and `"…T12:00:00Z" > "…T12:00:00.123Z"` bytewise (`Z` sorts above `.`), so an un-normalized whole-second bound would skip the first sub-second of its own range.
**Approved**: pending

**Decision**: `activitySince` truncates to whole seconds and names the parameter `since` itself.
**Rationale**: The source says the activity table stores whole-second `UTCTimestamp` strings, for which the fractional form would compare wrongly byte for byte, and no caller ever named the parameter (test: activitySinceTakesOnlyTheTextAndItsRefusalNamesSince).
**Approved**: pending

**Decision**: Validation delegates to `TimestampParsing.parseISO8601` rather than a local parser.
**Rationale**: The source calls it Core's shared validator so the CLI that checks a flag and the daemon that reads it accept exactly the same strings (test: activitySinceAcceptsExactlyWhatCoreAccepts).
**Approved**: pending

