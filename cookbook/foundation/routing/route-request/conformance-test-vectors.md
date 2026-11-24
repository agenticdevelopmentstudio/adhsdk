
Tests named below are in the `RouteRequest` suite (`RouteRequestTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| route-request-001 | path-components | Path `//sessions//abc/`, then path `/`. | `["sessions", "abc"]`, then `[]` (test: pathComponentsDropEmptySegments). |
| route-request-002 | query-last-value | `queryValues` `["a": ["1","2","3"]]`, then no `a`. | `query("a")` is `"3"`, then `nil` (test: queryReturnsTheLastOfRepeatedValues). |
| route-request-003 | query-all-wire-order | `["a": ["z","b","m"]]`, then no `a`. | `["z","b","m"]`, then `[]` (test: queryAllKeepsWireOrder). |
| route-request-004 | query-int-default | `n=12` with default 5; `n=x` with default 5; no `n` with no default. | 12, 5, 0 (test: queryIntFallsBackToTheDefault). |
| route-request-005 | limit-default | No `limit`, `boundedLimit(default: 50, max: 500)`. | 50 (test: missingLimitUsesTheDefault). |
| route-request-006 | limit-in-range | `limit=120`, default 50, max 500. | 120 (test: limitInRangeIsHonoured). |
| route-request-007 | limit-capped, limit-clamp-is-silent | `limit=99999`, default 50, max 500. | 500 (test: limitAboveTheCeilingIsCappedAtIt). |
| route-request-008 | limit-floored-at-one, limit-clamp-is-silent | `limit=-1`, default 50, max 500. | 1, not unlimited (test: negativeLimitIsRaisedToOneRatherThanMeaningUnlimited). |
| route-request-009 | limit-floored-at-one | `limit=0`, default 50, max 500. | 1 (test: zeroLimitIsRaisedToOne). |
| route-request-010 | limit-default | `limit=all`, default 50, max 500. | 50 (test: unparseableLimitFallsBackToTheDefault). |
| route-request-011 | limit-default | No `limit`, default 20000, max 10000. | 10000 (test: anAbsurdDefaultStillCannotExceedItsOwnCeiling). |
| route-request-012 | offset-default | No `offset`. | 0 (test: missingOffsetIsZero). |
| route-request-013 | offset-in-range | `offset=250`. | 250 (test: offsetInRangeIsHonoured). |
| route-request-014 | offset-floored-at-zero | `offset=-40`. | 0 (test: negativeOffsetIsFlooredAtZero). |
| route-request-015 | timestamp-absent-is-unbounded | No `since`. | `.success(nil)` (test: aMissingTimestampMeansAnUnboundedWindow). |
| route-request-016 | timestamp-absent-is-unbounded | `since=` (empty). | `.success(nil)` (test: anEmptyTimestampMeansAnUnboundedWindow). |
| route-request-017 | timestamp-normalized | `since=2026-01-31T00:00:00Z`. | `.success("2026-01-31T00:00:00.000Z")` (test: aWholeSecondBoundIsNormalisedToFractionalSeconds). |
| route-request-018 | timestamp-fraction-preserved | `since=2026-01-31T00:00:00.500Z`. | `.success("2026-01-31T00:00:00.500Z")` (test: aFractionalBoundSurvivesUnchanged). |
| route-request-019 | timestamp-rebased-to-utc | `since=2026-01-31T02:00:00+02:00`. | `.success("2026-01-31T00:00:00.000Z")` (test: anOffsetBoundIsRebasedOntoUTC). |
| route-request-020 | timestamp-validated, failure-message-format | `since=yesterday`. | `.failure` whose message contains `since` and `yesterday` (test: aWordIsRejectedRatherThanSortingAboveEveryRealTimestamp). |
| route-request-021 | timestamp-validated | `since=2026`. | `.failure` (test: aBareYearIsRejectedRatherThanSilentlyMeaningEverything). |
| route-request-022 | failure-message-format | `until=nope`, `validatedTimestamp("until")`. | `.failure` whose message contains `until` (test: theRejectionNamesTheParameterThatWasWrong). |
| route-request-023 | activity-since-whole-seconds | `activitySince("2026-10-03T11:00:00.500Z")`. | `.success("2026-10-03T11:00:00Z")` (test: activitySinceTruncatesToWholeSeconds). |
| route-request-024 | activity-since-absent-is-empty | `activitySince(nil)` and `activitySince("")`. | `.success("")` for both (test: activitySinceTreatsNilAndEmptyAsNoBound). |
| route-request-025 | activity-since-name | `activitySince("yesterday")` through a function typed `(String?) -> Result`. | `.failure` whose message contains `` `since` `` (test: activitySinceTakesOnlyTheTextAndItsRefusalNamesSince). |
| route-request-026 | same-validator-as-core | Each of `2026-10-01T00:00:00Z`, `2026-10-01T00:00:00.250Z`, `2026-10-01T02:00:00+02:00`, `2026-10-01 00:00:00`, `2026-10-01`, `yesterday`, `2026`, `2026-13-01T00:00:00Z`. | `activitySince` succeeds exactly when `TimestampParsing.parseISO8601` returns a date (test: activitySinceAcceptsExactlyWhatCoreAccepts). |
| route-request-027 | init-defaults | `RouteRequest(method: "GET", path: "/")`. | Empty `queryValues`, empty `headers`, empty `body` (derived from the initializer defaults; no test beside the source). |
| route-request-028 | same-validator-as-core, timestamp-validated | `since=2026-10-01 00:00:00` (the SQLite shape), `validatedTimestamp("since")`. | `.failure` (derived from `TimestampParsing.parseISO8601`, which refuses that shape; no test beside the source). |
| route-request-029 | same-validator-as-core, timestamp-validated | `since=2026-10-01` (a bare date), `validatedTimestamp("since")`. | `.failure` (derived; no test beside the source). |
| route-request-030 | same-validator-as-core, timestamp-validated | `since=2026-13-01T00:00:00Z` (month 13), `validatedTimestamp("since")`. | `.failure` (derived; no test beside the source). |
| route-request-031 | normalized-timestamp-static | `RouteRequest.normalizedTimestamp("2026-01-31T00:00:00Z", name: "until")`, then `normalizedTimestamp("nope", name: "until")`. | `.success("2026-01-31T00:00:00.000Z")`, then `.failure` whose message contains `until` (derived; no test beside the source). |
| route-request-032 | fields | `RouteRequest(method: "POST", path: "/x", queryValues: ["a": ["1"]], headers: ["h": "v"], body: Data([1, 2]))`. | Each of `method`, `path`, `queryValues`, `headers` and `body` reads back exactly as given (derived from the initializer; no test beside the source). |
| route-request-033 | value-semantics | Two requests built from identical arguments, then two that differ only in `body`. | Equal, then not equal (derived from the synthesized `Equatable`; no test beside the source). |
| route-request-034 | pure-and-synchronous | Call `boundedLimit(default: 50, max: 500)` and `validatedTimestamp("since")` twice on one request. | Both calls return equal results and the request still equals its original (derived; no test beside the source). |

