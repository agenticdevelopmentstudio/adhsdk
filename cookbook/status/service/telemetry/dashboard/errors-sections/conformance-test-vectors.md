
Vectors 001 to 018 are traced to the `errors sections: conformance vectors` tests in `telemetry-dashboard-sections.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| errors-sections-001 | active-rule | Level `error`, last seen now | `active` true |
| errors-sections-002 | active-rule | Level `FATAL` | `active` true |
| errors-sections-003 | active-rule | Level `warning`; or last seen 48 hours ago; or `lastSeen` null; or level null | `active` false in each case |
| errors-sections-004 | active-rule | Project `scratch` with allowlist `['app']`; project `app` with the same list | `active` false for `scratch`, true for `app` |
| errors-sections-005 | issue-order, summary-counts | Three issues, one active, 104 events in all, resolved 7 | `active` 1, `backlog` 2, `events` 104, `resolved` 7, `complete` true; issues ordered active first, then by count |
| errors-sections-006 | by-type | Issues with types `TypeError` (100 events), `SyntaxError` (3) and none (1) | Groups `TypeError`, `SyntaxError` and `Other`, ordered by events |
| errors-sections-007 | new-per-day | Two issues first seen on the same UTC day, a third with no `firstSeen` | That day's bucket is 2 and `newPerDay` sums to 2 |
| errors-sections-008 | issue-extras | Raw issue with `shortId` `ADH-2`, type `SyntaxError`, filename `/x.js`, release `abc` | Row carries those four values |
| errors-sections-009 | resolved-cached | Two list refreshes inside the TTL | One `is:resolved` read; both sections show `resolved` 3 |
| errors-sections-010 | resolved-failure-not-kept | A failed resolved read, then a good one | First call null, the next reads again and returns 2 |
| errors-sections-011 | failed-read-throws | The unresolved read returns not ok | `loadErrorIssues` rejects with `GlitchTip issues could not be read` |
| errors-sections-012 | iso-ms | `null`, `''`, `not a date` | null for each |
| errors-sections-013 | judging-inputs | `loadErrorIssues` with allowlist `['app']` and `nowMs` 1000 | Each issue is judged with `{ nowMs: 1000, frozen: false, allowlist: ['app'] }`; with a null allowlist, no project filter applies |
| errors-sections-014 | section-window | `loadErrorIssues` at a given `nowMs` | The section's `buckets` equal those of `rangeWindow('30d', nowMs)` |
| errors-sections-015 | summary-flags | An unresolved list the fetcher reports `complete` false | `summary.complete` is false |
| errors-sections-016 | resolved-optional | The resolved count is null because the resolved read failed | `loadErrorIssues` still returns the issue list, with `summary.resolved` null |
| errors-sections-017 | resolved-cap-kept | A resolved walk that hits the 20-page cap, then a second call inside the TTL | The first call returns null, and the second returns null without reading again |
| errors-sections-018 | resolved-never-throws | A resolved read that throws | The counter's function resolves null and does not reject |
