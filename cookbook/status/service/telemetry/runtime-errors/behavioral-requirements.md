
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

