
- **iso-ms**: `isoMs(iso)` MUST return the epoch milliseconds of an ISO string, and null when the input is null, empty or unreadable. The board reads null as not current.
- **issue-mapping**: `toErrorIssues` MUST return one `ErrorIssue` per raw issue, in the same order, with `id`, `title`, `level`, `count`, `userCount`, `firstSeen`, `lastSeen`, `project` and `permalink` taken from the shared GlitchTip mapper `mapIssues`.
- **issue-extras**: Each `ErrorIssue` MUST also carry `shortId`, `type` (the metadata type), `source` (the metadata filename) and `release` (the last release version), each null when absent or empty.
- **active-rule**: `ErrorIssue.active` MUST equal `errorCountsAsProblem({ project, level, lastSeenMs }, judging)`, the board's whole rule including its allowlist: an error or fatal issue, seen in the last 24 hours, in an allowed project.
- **judging-inputs**: `loadErrorIssues` MUST judge with `{ nowMs, frozen: false, allowlist }`, where `allowlist` is the configured GlitchTip project list or null.
- **issue-order**: `summarizeIssues` MUST return `issues` sorted active first, then by event `count` descending, and MUST NOT reorder the input array.
- **summary-counts**: `summary.active` MUST count issues with `active` true, `summary.backlog` MUST be the total minus `active`, and `summary.events` MUST be the sum of `count` over all issues.
- **by-type**: `summary.byType` MUST group issues by `type` (null grouped as `Other`) with `issues` and `events` per group, sorted by `events` descending.
- **new-per-day**: `summary.newPerDay` MUST count issues by the UTC day of `firstSeen` (an issue with no `firstSeen` is not counted), aligned to the window's buckets with `alignToBuckets`.
- **section-window**: `loadErrorIssues` MUST summarise over `rangeWindow('30d', nowMs)`, and the section's `buckets` MUST be that window's buckets.
- **summary-flags**: `summary.resolved` MUST be the resolved count (null when not counted) and `summary.complete` MUST be false when the unresolved list was cut short.
- **failed-read-throws**: When the unresolved read fails, `loadErrorIssues` MUST throw `GlitchTip issues could not be read`, so the section cache keeps its last answer and its `active` flags rather than judging anything as a frozen feed.
- **resolved-optional**: A failure to count resolved issues MUST NOT fail the issue list; the count is a nice-to-have on the KPI row.
- **resolved-cached**: `resolvedCounter(env, ttlMs)` MUST read the resolved list at most once per `ttlMs` (default 60 minutes), through a single flight, and MUST return the same count to every caller within that time.
- **resolved-value**: The resolved count MUST be the length of the `is:resolved` list when the walk is complete, and null when the walk is capped (see Walk outcomes below).
- **resolved-failure-not-kept**: A resolved read that failed, or that was interrupted after its first page, MUST give null to the caller and MUST NOT be cached, so the next call reads again.
- **resolved-cap-kept**: A capped walk MUST be cached as null for the whole TTL, since walking again would meet the same limit.
- **resolved-never-throws**: The function returned by `resolvedCounter` MUST NOT reject; every failure becomes null.

Walk outcomes. The GlitchTip fetcher classifies each walk of an issue list, and these requirements use its terms:

- **failed**: the read is not ok, because no page could be read at all.
- **interrupted**: a page after the first failed, so the walk was cut short and the fetcher flags it `interrupted`.
- **capped**: the walk finished without being interrupted but is not complete, because it hit the page cap, met a repeated cursor, or got a full page with no way forward.
- **complete**: the whole list was read.

