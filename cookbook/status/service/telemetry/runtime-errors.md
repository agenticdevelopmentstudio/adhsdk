---
id: c116715f-2986-4554-a779-97e99d875c54
title: "Runtime Errors"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Rules for Vercel runtime errors: which events count, how they group by shape, and how the 24-hour report is ordered, capped and dated."
platforms:
  - typescript
  - web
tags:
  - telemetry
  - errors
  - vercel
  - status-server
depends-on: []
related:
  - 8648272e-2da3-46fc-b9e8-5148dacdbcff
references: []
approved-by: ""
approved-date: ""
---

# Runtime Errors

## Overview

`runtime-errors.ts` holds the rules for Vercel runtime errors, kept apart from the fetcher (network) and the store (SQL) so each is testable alone: which raw events count (`logEventToEntry`, `responseEventToEntry`), how entries group (`normalizePath`, `messageShape`, `groupIdentity`, `groupRuntimeEntries`), and how the report is ordered, capped and dated (`compareRuntimeGroups`, `runtimeErrorsReport`, `loadRuntimeErrorsReport`). The store and the route both call these functions, so there is one copy of each rule. Each read asks Vercel for the last 24 hours and the store replaces its groups with the result, so a group's `count` is its count in that window and nothing is deduplicated across reads. All functions are synchronous and pure except `loadRuntimeErrorsReport`, which reads the store. The data shapes (`RuntimeLogEntry`, `RuntimeErrorGroup`, `RuntimeErrorsRead`, `RuntimeErrorsReport`) live in `types.ts`. `GET /errors/runtime` and the errors dashboard's `runtime` section serve the report.

## Behavioral Requirements

### Levels

- **level-order**: `RUNTIME_LEVELS` MUST list the levels worst first: `fatal`, `error`, `warning`, `info`, `debug`, `trace`.
- **level-rank**: `levelRank` MUST return a higher number for a worse level, `5` for `fatal` down to `0` for `trace`.
- **level-rank-unknown**: `levelRank` MUST return `-1` for an unknown, `null` or `undefined` level, so it sorts below every known one.
- **worse-level**: `worseLevel(a, b)` MUST return `b` only when `levelRank(b)` is strictly greater than `levelRank(a)`, otherwise `a`.

### Events to entries

- **project-filter**: Both entry builders MUST return `null` when the event's `projectId` is not a key of the supplied `projects` map (a staging or testing project's own production environment is not in it).
- **timestamp-required**: Both entry builders MUST return `null` when `timestamp` is not a non-empty string that `Date.parse` accepts.
- **log-level-filter**: `logEventToEntry` MUST keep an event only when its `level` is exactly `error` or `fatal`; a missing, empty or non-string level reads `info` and is dropped.
- **log-entry-fields**: A kept log event MUST become an entry with `source` from `raw.source` (default `unknown`), `status` null and `message` from `raw.message` (empty string when it is not a string).
- **response-filter**: `responseEventToEntry` MUST keep an event only when `httpStatus` is a finite number of at least 500.
- **response-entry-fields**: A kept response event MUST become an entry with `level` `error`, `source` `response`, the status as `status` and `message` `HTTP <status>`.
- **common-fields**: A kept entry MUST carry `project` (the project's name), `deploymentId` (empty string when absent), `requestId`, `timestampMs`, `method` and the cleaned `path`; absent or empty strings read null.
- **domain-precedence**: An entry's `domain` MUST be the first non-empty of the event's `domain`, the project's `domain`, and the event's `requestHostname`, else null.
- **path-cleaning**: The entry `path` MUST be the request path cut at the first `?` or `#`; a path that is empty after the cut MUST read `/`; an absent path stays null. It is not yet normalized.

### Normalization and shape

- **id-segment**: A path segment MUST read as an id when it is all digits, a UUID, a hex run of 12 or more characters containing a digit, or a token of 20 or more characters of letters, digits, `_` and `-` containing at least one letter and at least one digit. The UUID and hex tests MUST ignore case (`3F2504E0-...` and `3f2504e0-...` both match).
- **normalize-path**: `normalizePath` MUST replace each non-empty id segment with `:id`, keep every other segment, keep the slashes, and return null for null.
- **message-head**: `messageHead` MUST return the first line, trimmed, cut to at most 200 characters. A line break is `\n` or `\r\n`; a lone `\r` is not a break.
- **message-shape**: `messageShape` MUST replace every id-like token with `:id`, then replace every run of digits with `#`. A token is a maximal run of letters, digits, `_` and `-`; it is id-like when it is not all digits and passes the `id-segment` test (a UUID, a hex run of 12 or more characters containing a digit, or a token of 20 or more characters containing a letter and a digit).
- **shape-before-cut**: `groupIdentity` MUST compute the shape from the whole first line and only then cut it to 200 characters, never from the cut head.
- **group-key**: `groupIdentity` MUST return a `key` that is the first 32 characters of the lower-case hex SHA-256 of the UTF-8 bytes of a JSON array of `project`, `source`, `method`, normalized `path`, `status` and the cut message shape, in that order. The array is serialized as JSON: strings quoted and escaped, a null as `null`, `status` as a bare number. Deployment, domain, level and request id MUST NOT enter the key.
- **group-identity-fields**: `groupIdentity` MUST also return the normalized `path` and the message head as written, for a group to show as its sample.

### Grouping a read

- **group-fold**: `groupRuntimeEntries` MUST produce one group per distinct key, with `count` the number of entries in it.
- **group-level**: A group's `level` MUST be the worst level of its entries by `worseLevel`. A group made only of unknown levels keeps its first entry's level, because `worseLevel` keeps `a` unless `b` ranks strictly higher.
- **group-times**: `firstSeen` MUST be the earliest entry timestamp and `lastSeen` the latest, both as ISO strings.
- **group-newest-event**: The group's `deploymentId` MUST come from its newest entry; an entry with a timestamp equal to or later than the current `lastSeen` replaces it, so on a tie the later entry in input order wins.
- **group-fallbacks**: When the newest entry has a null `domain` or `requestId`, the group MUST keep the earlier non-null `domain` and `sampleRequestId`. `deploymentId` has no such fallback.
- **group-first-entry-sample**: The group's displayed `message`, `path`, `project`, `source`, `method` and `status` MUST be those of the first entry that created it.
- **group-empty**: An empty entries array MUST give an empty groups array.

### Report

- **report-order**: `compareRuntimeGroups` MUST order worst level first, then higher `count`, then later `lastSeen`, then ascending `key`. `lastSeen` (a fixed-format ISO string) and `key` (lower-case hex) MUST be compared as plain strings, ordinally; the source's `localeCompare` gives the same order for strings of these shapes.
- **report-cap**: `runtimeErrorsReport` MUST return at most `RUNTIME_ERROR_REPORT_CAP` (200) groups while `total` counts all of them.
- **report-fields**: The report MUST carry `generatedAt` (from `nowMs`), `window` `24h`, `readAt`, `complete` and `total`.
- **report-read-dating**: `readAt` MUST be the ISO time of `read.readAtMs`, or null when there is no read. `complete` MUST be `read.complete`, or true when there is no read.
- **report-no-rewindow**: The report MUST NOT age groups out against `nowMs`; an old read stays, dated by `readAt`, so a failing reader shows old groups as old.
- **report-input-untouched**: `runtimeErrorsReport` MUST sort a copy and leave the given groups array unchanged.
- **report-load**: `loadRuntimeErrorsReport` MUST call `store.load()` and `store.lastRead()` concurrently and build the report from both, with `nowMs` defaulting to `Date.now()`.
- **report-load-errors**: A rejection from either store call MUST propagate to the caller unchanged; the function has no catch.

### Scope notes

- **constants**: `RUNTIME_ERROR_WINDOW_MS` MUST be 86,400,000 ms (24 hours). It is exported for callers and tests; the functions here do not apply it themselves.
- **entry-input-shape**: `RawRuntimeEvent` fields are all `unknown`; every field is read through a type guard, and a field of the wrong type reads as absent.

## Appearance

Not applicable — this is a set of pure rules and a report loader, not a visual component.

## States

Not applicable — these are stateless functions, not a visual component. The only runtime state, the stored snapshot and its last read, belongs to the store behind `RuntimeErrorsStore`.

## Accessibility

Not applicable — this is shared logic with no visual surface or interaction.

## Conformance Test Vectors

Every vector is a test in `runtime-errors.test.ts`; the one named `runtime-errors-NNN ...` in the final `conformance vectors` block covers it, and vectors 1 to 13 also name the older test that asserts the same thing (in brackets). Constant NOW is 2026-11-06T12:00:00Z; PROJECTS maps `prj_site` to name `site-production`, domain `site.example.com`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| runtime-errors-001 | log-level-filter, common-fields, domain-precedence ("keeps error and fatal lines, dated and placed by the event") | log event, level `error`, projectId `prj_site`, timestamp NOW | entry with level `error`, project `site-production`, domain `site.example.com`, `timestampMs` NOW, `status` null; level `fatal` keeps `fatal` |
| runtime-errors-002 | log-level-filter, timestamp-required, project-filter ("drops lower levels, undated events, and projects that are not production") | level `warning`; no level; timestamp `x`; projectId `prj_staging` | each returns null |
| runtime-errors-003 | path-cleaning, domain-precedence ("strips the query and fragment, and prefers the event's own domain") | path `/a/b?token=x#frag`, method POST, domain `other.example.com`; and path `?q=1` | path `/a/b`, method `POST`, domain `other.example.com`; second path `/` |
| runtime-errors-004 | response-filter, response-entry-fields ("keeps 5xx responses as error entries") | response event, `httpStatus` 503, requestId `req_9` | level `error`, source `response`, status 503, message `HTTP 503`, requestId `req_9` |
| runtime-errors-005 | response-filter ("drops anything below 500 and anything without a status") | `httpStatus` 404; no status | null; null |
| runtime-errors-006 | normalize-path, id-segment ("reads id-like segments as :id and leaves words alone") | `/posts/123/edit`; `/u/3f2504e0-4f89-11d3-9a0c-0305e82c3301`; `/blob/deadbeef1234abcd`; `/s/V1StGXR8Z5jdHi6BmyT2x`; `/about/facebook-account`; `/`; null | `/posts/:id/edit`; `/u/:id`; `/blob/:id`; `/s/:id`; unchanged; `/`; null |
| runtime-errors-007 | group-key, group-identity-fields, message-head ("keys on the normalized path and the first message line, stably") | entries with paths `/api/posts/1` and `/api/posts/2`, messages `boom` plus differing stacks; one with status 502; one message of 300 `x` | equal 32-hex keys for the first two; path `/api/posts/:id`, message `boom`; 502 changes the key; message head length 200 |
| runtime-errors-008 | shape-before-cut ("shapes the whole first line before cutting it") | `Order 1: <185 x> tail` and `Order 1234567: <185 x> tail` | same key; long head length 200 |
| runtime-errors-009 | message-shape ("a message that embeds an id, number or timestamp is one error") | `Order 8231 not found`; `user <uuid> has no plan`; `timeout after 3000ms at 2026-11-06T10:00:00Z`; `Cannot read properties of undefined (reading 'id')` | `Order # not found`; `user :id has no plan`; `timeout after #ms at #-#-#T#:#:#Z`; last unchanged |
| runtime-errors-010 | group-fold, group-key ("a message that embeds an id...") | 40 entries, paths `/api/orders/<n>`, messages `Order <n> not found` | 1 group, count 40, path `/api/orders/:id`, message `Order 8231 not found` |
| runtime-errors-011 | group-level, group-times, group-newest-event, worse-level ("folds a read") | three same-key entries at 1000 (error, dpl_old, r1), 3000 (error, dpl_new, r2), 2000 (fatal, dpl_old, r3); and `worseLevel("error","mystery")` | one group: count 3, level `fatal`, firstSeen ISO(1000), lastSeen ISO(3000), deploymentId `dpl_new`, sampleRequestId `r2`; worseLevel gives `error` |
| runtime-errors-012 | report-order, report-cap, report-fields, report-read-dating ("orders worst level first...") | groups few (count 2), many (count 9), fatal (count 1); read 5 min before NOW, complete false; then 205 groups with no read | order fatal, many, few; `generatedAt` ISO(NOW), window `24h`, readAt ISO(NOW-5min), complete false, total 3; second: total 205, readAt null, complete true, 200 groups |
| runtime-errors-013 | report-no-rewindow ("does not age groups out against the clock") | one group last seen 3 windows ago; read 2 windows ago | total 1; readAt is the read time |
| runtime-errors-014 | level-rank-unknown, level-rank | `levelRank("fatal")`, `levelRank("trace")`, `levelRank("mystery")`, `levelRank(null)` | 5, 0, -1, -1 |
| runtime-errors-015 | group-newest-event | two entries with equal timestamps, deployments d1 then d2 | `deploymentId` d2 |
| runtime-errors-016 | report-load-errors | store whose `load()` rejects | `loadRuntimeErrorsReport` rejects with that error |
| runtime-errors-017 | level-order | `RUNTIME_LEVELS` | `["fatal", "error", "warning", "info", "debug", "trace"]` |
| runtime-errors-018 | log-entry-fields | Log event, level `error`, valid project and timestamp, no `source`, `message` the number 42 | Entry with `source` `unknown`, `status` null, `message` `""` |
| runtime-errors-019 | common-fields | Log event, level `error`, valid project and timestamp, no `deploymentId` | Entry with `deploymentId` `""` |
| runtime-errors-020 | group-fallbacks, group-newest-event | Two same-key entries: at 1000 with domain `d.example.com`, requestId `r1`, deployment `d1`; at 3000 with domain null, requestId null, deployment `""` | One group: `domain` `d.example.com`, `sampleRequestId` `r1`, `deploymentId` `""` |
| runtime-errors-021 | group-first-entry-sample | Two same-key entries, the first path `/o/1` message `Order 1 not found`, the second path `/o/2` message `Order 2 not found` | Group `path` `/o/:id`, `message` `Order 1 not found` |
| runtime-errors-022 | report-input-untouched | Groups array `[few, many]`, then `runtimeErrorsReport` over it | The report lists `many` then `few`; the original array is still `[few, many]` |
| runtime-errors-023 | report-load | A store whose `load()` and `lastRead()` both record that they were called; `loadRuntimeErrorsReport(store)` with no `nowMs` | Both calls started before either result is awaited; the report holds the loaded groups and the read's `readAt`; `generatedAt` is the current time |
| runtime-errors-024 | group-level | Two same-key entries with levels `mystery` and `other` | Group `level` `mystery` |
| runtime-errors-025 | message-head | `a\r\nb`; `a\nb`; `a\rb` | `a`; `a`; `a\rb` |
| runtime-errors-026 | id-segment | `/u/3F2504E0-4F89-11D3-9A0C-0305E82C3301`; `/b/DEADBEEF1234` | `/u/:id`; `/b/:id` |
## Edge Cases

- **Empty entries**: `groupRuntimeEntries([])` MUST return `[]`; `runtimeErrorsReport([], null, now)` MUST give `total` 0, `readAt` null, `complete` true.
- **Missing level**: a log event with no level MUST be dropped as `info`.
- **Wrong-typed fields**: a numeric `requestPath` or an empty-string `requestId` MUST read as absent (null).
- **Empty path after cut**: a path of only a query string MUST become `/`; a literally empty path stays null.
- **Message with no newline or empty message**: the head MUST be the trimmed whole line, or empty.
- **Multi-line message**: only the first line enters the head and the key; stack lines never split a group.
- **Long message**: the head MUST be cut to 200 characters but the shape MUST be taken first.
- **Ids of varying length in messages or paths**: MUST land in one group.
- **Digit-only word in a path**: `/2024` reads `:id`; `facebook-account` stays a word.
- **Unknown level in a group**: `worseLevel` keeps the known level; a group made only of unknown levels keeps the first entry's (see `#requirements/group-level`).
- **Equal sort keys**: report order falls through count, `lastSeen`, then `key`, so it is total and stable.
- **More than 200 groups**: the report MUST cap at 200 and keep `total` at the true count.
- **Stale read**: groups from an old read MUST stay, dated by `readAt`.
- **No read yet**: `readAt` null and `complete` true.
- **Store unavailable**: a rejecting `load` or `lastRead` MUST propagate; this module neither retries nor falls back.
- **Concurrent access**: the pure functions share no state and cannot interleave; the two store reads are concurrent and not atomic (see `report-load-consistency`, below).
- **report-load-consistency**: NEEDS REVIEW: Not implemented in source. `loadRuntimeErrorsReport` reads the groups and the last read in two separate store calls, while `save` replaces both in one transaction, so a save landing between them can pair groups with another read's `readAt` and `complete`. Evidence needed: whether the libsql store serializes `load`, `lastRead` and `save` on one connection, or a single transactional read method.
- **Offline or network**: not applicable here; the network belongs to the fetcher (`fetchers/vercel-runtime.ts`).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `RUNTIME_ERROR_WINDOW_MS` | number (exported constant) | 86,400,000 | The window one read covers. |
| `RUNTIME_ERROR_REPORT_CAP` | number (exported constant) | 200 | Most groups in a report. |
| `RUNTIME_LEVELS` | readonly string array | fatal, error, warning, info, debug, trace | Level ranking, worst first. |
| message head limit | number (private constant `MESSAGE_MAX`) | 200 | Characters kept in a head and a shape. |
| `projects` | map of project id to `RuntimeProject` (name, domain) | none (required) | Injected into the entry builders; the production-project filter. |
| `store` | `Pick<RuntimeErrorsStore, "load" \| "lastRead">` | none (required) | Injected into `loadRuntimeErrorsReport`. |
| `nowMs` | number | `Date.now()` | Clock for `generatedAt`. |

## Deep Linking

Not applicable: the module has no routes or URLs; `GET /errors/runtime` is mounted elsewhere. `sampleRequestId` is the id a person looks up in Vercel's logs.

## Localization

Not applicable: the only strings generated are the machine-facing `HTTP <status>` message and the `24h` window label; there is no user-facing text.

## Accessibility Options

Not applicable: no visual output.

## Feature Flags

Not applicable: the source reads no flag. Whether the read runs is the fetcher's concern (it asks nothing without a Vercel token).

## Analytics

Not applicable: the module emits no event or metric.

## Privacy

- **Data collected**: Vercel log messages (first line, 200 characters), request paths with ids replaced by `:id` in groups, methods, statuses, domains, deployment ids and one request id per group. Messages can contain whatever the application logged.
- **Storage**: Not stored by this module; the store behind `RuntimeErrorsStore` keeps the grouped snapshot. The query string and fragment are removed before grouping.
- **Transmission**: Not transmitted by this module; the report is returned to the route that serves it.
- **Retention**: Each successful read replaces the stored groups, so what persists is the 24-hour window of the last successful read, not a window ending now. While reads fail, that older snapshot stays (see `#requirements/report-no-rewindow`).

## Logging

Not applicable: the source contains no log call.

## Platform Notes

- **SwiftUI**: Port the functions as a Foundation-only module. `CryptoKit.SHA256` gives the key (hex of the digest, first 32 characters); `NSRegularExpression` or Swift `Regex` for the id tests and `messageShape`; `ISO8601DateFormatter` with fractional seconds to match `toISOString()`. Take care that JavaScript string `slice` counts UTF-16 units while Swift `prefix` counts characters.
- **Compose**: Kotlin `MessageDigest.getInstance("SHA-256")` and `Regex`; `sortedWith` of a comparator chain; `java.time.Instant.toString()` for ISO times (check millisecond digits). `String.take(200)` counts UTF-16 units like the source.
- **React/Web**: The source is `src/telemetry/runtime-errors.ts` in `status-server`, using `node:crypto` `createHash`; types in `src/telemetry/types.ts`; store port in `src/storage/ports.ts`. Node only (not browser-safe because of `node:crypto`).
- **AppKit / UIKit**: No UI. Same port as SwiftUI.
- **WinUI 3**: Port as a class library. Use `System.Security.Cryptography.SHA256.HashData` with `Convert.ToHexStringLower(...)[..32]`; `System.Text.RegularExpressions.Regex` (set `RegexOptions.IgnoreCase` for UUID and hex tests, and `CultureInvariant`); `DateTimeOffset.UtcNow` and `ToString("O")` or `"yyyy-MM-ddTHH:mm:ss.fffZ"` to match `toISOString()`; `Task.WhenAll` for the two store reads, with `ConfigureAwait(false)`. Serialize the key input with `System.Text.Json` so null and number types match JSON (`JSON.stringify` of an array with nulls). Order with `OrderByDescending` / `ThenBy` and `string.CompareOrdinal`; note JavaScript `localeCompare` is culture-sensitive, so for ISO times and hex keys ordinal comparison is equivalent. In ASP.NET Core a minimal API route `app.MapGet("/errors/runtime", ...)` calls the loader. A WinUI view binds groups through an `ObservableCollection` on an `INotifyPropertyChanged` view model.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/runtime-errors.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/status-server/test/runtime-errors.test.ts` | confirmed (1.0.2) |

## Design Decisions

**Decision**: Keep the rules apart from the fetcher and the store.
**Rationale**: The header comment says each is then testable alone, and the store and the route share one copy of every rule.
**Approved**: pending

**Decision**: Each read replaces the stored groups instead of accumulating.
**Rationale**: Per the header comment, a group's count is then its count in the 24-hour window and nothing is deduplicated across reads.
**Approved**: pending

**Decision**: Group by message shape (ids read `:id`, digit runs read `#`) and normalized path.
**Rationale**: `Order 8231 not found` and `Order 8270 not found` are one error; without it every occurrence is its own group. The test "a message that embeds an id, number or timestamp is one error" records the case of 40 requests.
**Approved**: pending

**Decision**: Take the shape from the whole first line, then cut to 200 characters.
**Rationale**: A number of varying length would move the cut and split one error into a group per occurrence (comment in `groupIdentity`).
**Approved**: pending

**Decision**: Do not re-window groups against the clock.
**Rationale**: Per the `runtimeErrorsReport` comment, a reader whose reads fail should see old groups dated as old rather than watch them disappear.
**Approved**: pending

**Decision**: Treat an unknown level as below every known one (`-1`).
**Rationale**: A new Vercel level must not outrank `fatal`; the test `worseLevel("error","mystery")` returns `error`.
**Approved**: pending

**Decision**: Only a path segment with a digit counts as a hex or token id.
**Rationale**: Test `/about/facebook-account` stays a word while `/blob/deadbeef1234abcd` reads `:id`; words that happen to be hex letters must not be hidden.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

`separation-of-concerns` passes because the rules take no network or SQL. `unit-test-coverage` passes: `runtime-errors.test.ts` covers entry building, grouping, shape, ordering, the cap and the stale-read dating, and every vector 1 to 26 has its own test titled with its id. `data-retention-policy` passes because each save replaces the snapshot, so only the last 24-hour window persists. `data-integrity` is partial: the loader reads groups and the last read in two calls while the store saves them in one transaction, which is the open question on `report-load-consistency`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (runtime-errors.test.ts, 26 of 26 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Stated the id-token, case, line-break, hash-input and ordinal-comparison rules in the requirements, moved the report-load-consistency open question out of the requirements list into Edge Cases, added ten vectors for the uncovered requirements, marked unit-test coverage partial, clarified retention as bounded by the last successful read, and linked the fetchers recipe. |
