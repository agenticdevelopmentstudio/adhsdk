
**Decision**: The rules module is pure, with `now` as an input and every source passed in as data or a failure.
**Rationale**: Each rule can then be tested with fixtures and no clock, and the reading half can change without touching the judgement.
**Approved**: pending

**Decision**: A missing source, an errored section or a stalled monitor makes `complete` false, but an unconfigured provider does not.
**Rationale**: "No findings" must read as "don't know" when something was not read; a standing fact like a missing credential would otherwise make `complete` permanently false and teach readers to ignore it.
**Approved**: pending

**Decision**: Monitor findings come only from board problems, with the board's own severity, and a service with no problem is counted but never graded here.
**Rationale**: The board holds some services back on purpose (HTTP monitoring off, a degraded probe inside its confirm window, a testing-tier stale deploy kept minor); raising them here would grade them sooner and harder than the board does.
**Approved**: pending

**Decision**: A GlitchTip error is counted once: the board's per-project errors problem is dropped only while the issue list is current (read, no failed refresh, no GlitchTip refresh running, read to the end).
**Rationale**: A cached list from before a new crash would otherwise hide that crash. A PostHog refresh says nothing about the list, so it does not count, or every crash would appear twice.
**Approved**: pending

**Decision**: An unreachable provider is one finding, at the board's severity (else minor), and replaces the board's problem for it.
**Rationale**: The deploys the provider watches are not down, so the report must not invent a worse grade than the board's.
**Approved**: pending

**Decision**: Failing deploys come from the board's `failed` deploy problems, not from the newest row per target in the deploy feed.
**Rationale**: The feed's newest row may be a canceled or queued build, a preview the board ignores, or missing because newer rows pushed the failure out of its window.
**Approved**: pending

**Decision**: A cap that hides items raises its own overflow finding at the severity of the worst hidden item, and major or fatal items are ranked ahead of the cap.
**Rationale**: A cap must never turn a fatal into a minor or hide one. For runtime groups the store may already have dropped groups past its own cap; those sort after every listed one, so they are no worse than the last listed.
**Approved**: pending

**Decision**: A site is troubled at 5% failure (`FAILURE_RATE_HIGH`), and a site with errors but no requests is troubled.
**Rationale**: One aborted request in a month of traffic is not worth a finding, but errors with no requests to weigh them against still count.
**Approved**: pending

**Decision**: `digestAnalytics` raises no findings, only notes and a section; `digestUptime` raises minor findings only.
**Rationale**: Traffic is information, not an incident, and uptime below the floor is worth attention but not degraded status.
**Approved**: pending

