
- An empty issue list gives empty `issues` and `byType`, zero counts and a `newPerDay` of zeros over the window.
- A raw issue with no metadata gives a null `type`, `source` and `release`, and sits in the `Other` group.
- A `firstSeen` older than the window is dropped by the bucket alignment; it still counts toward `active`, `backlog` and `events`.
- A resolved walk cut short after its first page is not kept as "not counted" for the hour; the next refresh tries again.
- The unresolved fetch is bounded by the fetcher: pages of 100, at most 20 pages, and one 12 second budget for the whole walk, not per request. A list that hits the cap returns `complete` false.
- The resolved list is read only to take its length, because GlitchTip has no count endpoint; a resolved list that reaches the 20-page cap (2,000 issues) gives null.
- A null allowlist means no project filter on `active`; the config yields null when `GLITCHTIP_PROJECTS` is unset, blank or only separators. An empty array passed directly would match no project, so every issue would be inactive.
- `frozen` is always false here, so an issue list that is stale is never judged as a frozen feed; stale data is handled by the section cache keeping the last answer.

