
**Decision**: Every source is read through a wrapper that never throws, and a failed read is data (`{ ok: false, error }`).
**Rationale**: A report about a failing fleet must still arrive when one source is the thing that is failing. The rules module turns each failure into coverage and a major finding, so nothing is silent.
**Approved**: pending

**Decision**: The deadline is a `Promise.race` and does not cancel the work it abandons.
**Rationale**: The sources are shared reads and caches with no cancellation hook. The cost is that an abandoned read may finish later and is simply ignored.
**Approved**: pending

**Decision**: Dashboards get `wait` seconds to settle, and the first-read result is replaced by a second read whether or not settle succeeded.
**Rationale**: A cold refresh would otherwise return a "poll me" flag to a CLI or an agent that cannot poll. A dashboard still refreshing at the deadline is disclosed by the rules module as a coverage note, not read as healthy.
**Approved**: pending

**Decision**: Failing-deploy logs follow the board's failing list (`failingDeployProblems`), not the deploy feed.
**Rationale**: The report lists the board's failing deploys, so the logs must belong to those same builds. The test `logs=1 attaches...` uses an empty feed to pin this.
**Approved**: pending

**Decision**: With no scheduler in the process, the stale window is computed here from the newest stored probe with `defaultStaleAfterMs`.
**Rationale**: The monitor loop may run in another process; one stale rule (the scheduler's window) applies either way, so the two cannot disagree.
**Approved**: pending

**Decision**: Whole-answer time is bounded only by per-source deadlines, which add up in the deploy-log path.
**Rationale**: The log reads must follow the feed read, because the failing list is only needed for them. The open question on `whole-answer-deadline` records the one case that exceeds the stated allowance.
**Approved**: pending

