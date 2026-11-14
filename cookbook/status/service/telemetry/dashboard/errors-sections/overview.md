
The GlitchTip half of the Errors topic: every unresolved issue, read as the board reads it. The module turns the raw GlitchTip issue list into `ErrorIssue` rows, marks each row `active` with the board's own rule (`errorCountsAsProblem`), summarises the list into the KPI figures of an `ErrorsIssuesSection`, and supplies a cached count of resolved issues.

The module has one loader, `loadErrorIssues`, which the dashboard set hands to a section cache, and four helpers: the pure `isoMs`, `toErrorIssues` and `summarizeIssues`, and the stateful `resolvedCounter`, which holds a TTL cache and a single flight. It deliberately carries no events-per-day series, because GlitchTip's `stats_v2` answers 200 with nulls for every interval on this instance while issues are firing, which would draw a flat zero beside issues reporting hundreds of events.

